package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sqs"
	_ "github.com/jackc/pgx/v4/stdlib"
	"github.com/joho/godotenv"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// Prometheus Metrics (Golden Metrics: Latency, Traffic, Errors)
var (
	httpRequestsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total de requisições HTTP processadas por handler e status code",
		},
		[]string{"method", "handler", "code"},
	)

	httpRequestDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "Histograma de latência das requisições HTTP em segundos",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "handler"},
	)

	donationsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "donations_created_total",
			Help: "Total de doações processadas com sucesso por status",
		},
		[]string{"status"},
	)

	donationAmountTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "donation_amount_total",
			Help: "Valor acumulado de doações por ONG",
		},
		[]string{"ngo_id"},
	)
)

func init() {
	prometheus.MustRegister(httpRequestsTotal)
	prometheus.MustRegister(httpRequestDuration)
	prometheus.MustRegister(donationsTotal)
	prometheus.MustRegister(donationAmountTotal)
}

type Donation struct {
	ID        int       `json:"id"`
	NgoID     int       `json:"ngo_id"`
	Amount    float64   `json:"amount"`
	DonorName string    `json:"donor_name"`
	Status    string    `json:"status"`
	CreatedAt time.Time `json:"created_at"`
}

func (d *Donation) Validate() error {
	if d.NgoID <= 0 {
		return errors.New("ngo_id deve ser um numero inteiro positivo")
	}
	if d.Amount <= 0 {
		return errors.New("amount deve ser maior que zero")
	}
	if strings.TrimSpace(d.DonorName) == "" {
		return errors.New("donor_name e obrigatorio")
	}
	return nil
}

type App struct {
	DB          *sql.DB
	SqsSvc      *sqs.SQS
	SqsQueueURL string
}

func main() {
	_ = godotenv.Load()

	port := os.Getenv("PORT")
	if port == "" {
		port = "8082"
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL e obrigatoria")
	}

	db, err := sql.Open("pgx", dbURL)
	if err != nil {
		log.Fatalf("Erro ao abrir conexao com banco de dados: %v", err)
	}

	// Configuração do pool de conexões PostgreSQL (FinOps & Resiliência)
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(10)
	db.SetConnMaxLifetime(5 * time.Minute)

	if err := db.Ping(); err != nil {
		log.Printf("Aviso: Falha ao pingar banco de dados na inicializacao: %v", err)
	} else {
		log.Println("Conectado ao PostgreSQL com sucesso (donation-service).")
	}

	var sqsSvc *sqs.SQS
	queueURL := os.Getenv("AWS_SQS_URL")
	region := os.Getenv("AWS_REGION")
	if queueURL != "" && region != "" {
		sess, err := session.NewSession(&aws.Config{Region: aws.String(region)})
		if err != nil {
			log.Printf("Erro ao criar sessao AWS SQS: %v", err)
		} else {
			sqsSvc = sqs.New(sess)
			log.Println("Integracao com AWS SQS ativada.")
		}
	}

	app := &App{DB: db, SqsSvc: sqsSvc, SqsQueueURL: queueURL}

	mux := http.NewServeMux()
	mux.HandleFunc("/health", app.HealthHandler)
	mux.HandleFunc("/health/live", app.LivenessHandler)
	mux.HandleFunc("/health/ready", app.ReadinessHandler)
	mux.Handle("/metrics", promhttp.Handler())

	mux.HandleFunc("/donations", app.instrumentHandler("donations", app.DonationHandler))

	server := &http.Server{
		Addr:         ":" + port,
		Handler:      mux,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Graceful Shutdown
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)

	go func() {
		log.Printf("donation-service rodando na porta %s", port)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("Erro ao iniciar servidor HTTP: %v", err)
		}
	}()

	<-stop
	log.Println("Encerrando donation-service graciosamente...")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Printf("Erro durante shutdown do servidor: %v", err)
	}

	if err := db.Close(); err != nil {
		log.Printf("Erro ao fechar conexao do banco: %v", err)
	}

	log.Println("donation-service finalizado com sucesso.")
}

func (a *App) LivenessHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(`{"status":"alive","service":"donation-service"}`))
}

func (a *App) ReadinessHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if a.DB == nil || a.DB.Ping() != nil {
		w.WriteHeader(http.StatusServiceUnavailable)
		_, _ = w.Write([]byte(`{"status":"not_ready","database":"disconnected","service":"donation-service"}`))
		return
	}
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(`{"status":"ready","database":"connected","service":"donation-service"}`))
}

func (a *App) HealthHandler(w http.ResponseWriter, r *http.Request) {
	a.ReadinessHandler(w, r)
}

func (a *App) instrumentHandler(handlerName string, handler http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rw := &responseWriterDelegator{ResponseWriter: w, statusCode: http.StatusOK}
		handler(rw, r)
		duration := time.Since(start).Seconds()

		httpRequestDuration.WithLabelValues(r.Method, handlerName).Observe(duration)
		httpRequestsTotal.WithLabelValues(r.Method, handlerName, strconv.Itoa(rw.statusCode)).Inc()
	}
}

type responseWriterDelegator struct {
	http.ResponseWriter
	statusCode int
}

func (r *responseWriterDelegator) WriteHeader(code int) {
	r.statusCode = code
	r.ResponseWriter.WriteHeader(code)
}

func (a *App) DonationHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodPost {
		var d Donation
		if err := json.NewDecoder(r.Body).Decode(&d); err != nil {
			w.WriteHeader(http.StatusBadRequest)
			_, _ = w.Write([]byte(`{"error":"Payload JSON invalido"}`))
			return
		}

		if err := d.Validate(); err != nil {
			w.WriteHeader(http.StatusUnprocessableEntity)
			_ = json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
			return
		}

		d.Status = "APPROVED" // Simulação do gateway de pagamento

		err := a.DB.QueryRow(
			"INSERT INTO donations (ngo_id, amount, donor_name, status) VALUES ($1, $2, $3, $4) RETURNING id, created_at",
			d.NgoID, d.Amount, d.DonorName, d.Status,
		).Scan(&d.ID, &d.CreatedAt)

		if err != nil {
			log.Printf("Erro ao salvar doacao no banco: %v", err)
			w.WriteHeader(http.StatusInternalServerError)
			_, _ = w.Write([]byte(`{"error":"Erro interno ao processar doacao"}`))
			return
		}

		// Registrar Métricas SRE
		donationsTotal.WithLabelValues(d.Status).Inc()
		donationAmountTotal.WithLabelValues(strconv.Itoa(d.NgoID)).Add(d.Amount)

		// Publicação Assíncrona AWS SQS
		if a.SqsSvc != nil && a.SqsQueueURL != "" {
			go a.sendNotificationEvent(d)
		}

		w.WriteHeader(http.StatusCreated)
		_ = json.NewEncoder(w).Encode(d)
		return
	}

	if r.Method == http.MethodGet {
		rows, err := a.DB.Query("SELECT id, ngo_id, amount, donor_name, status, created_at FROM donations ORDER BY id DESC LIMIT 100")
		if err != nil {
			log.Printf("Erro ao consultar doacoes: %v", err)
			w.WriteHeader(http.StatusInternalServerError)
			_, _ = w.Write([]byte(`{"error":"Erro interno ao consultar doacoes"}`))
			return
		}
		defer rows.Close()

		donations := []Donation{}
		for rows.Next() {
			var d Donation
			if err := rows.Scan(&d.ID, &d.NgoID, &d.Amount, &d.DonorName, &d.Status, &d.CreatedAt); err != nil {
				log.Printf("Erro ao ler registro de doacao: %v", err)
				continue
			}
			donations = append(donations, d)
		}

		w.WriteHeader(http.StatusOK)
		_ = json.NewEncoder(w).Encode(donations)
		return
	}

	w.WriteHeader(http.StatusMethodNotAllowed)
	_, _ = w.Write([]byte(`{"error":"Metodo nao permitido"}`))
}

func (a *App) sendNotificationEvent(d Donation) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	body, err := json.Marshal(d)
	if err != nil {
		log.Printf("Erro ao serializar evento de doacao para SQS: %v", err)
		return
	}

	_, err = a.SqsSvc.SendMessageWithContext(ctx, &sqs.SendMessageInput{
		MessageBody: aws.String(string(body)),
		QueueUrl:    aws.String(a.SqsQueueURL),
		MessageAttributes: map[string]*sqs.MessageAttributeValue{
			"EventType": {
				DataType:    aws.String("String"),
				StringValue: aws.String("DonationCreated"),
			},
		},
	})
	if err != nil {
		log.Printf("Falha ao despachar evento para AWS SQS: %v", err)
	} else {
		log.Printf("Evento de doacao ID %d despachado para SQS com sucesso.", d.ID)
	}
}