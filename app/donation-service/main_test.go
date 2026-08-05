package main

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func TestDonationValidation(t *testing.T) {
	tests := []struct {
		name     string
		donation Donation
		wantErr  bool
	}{
		{
			name: "Valid donation",
			donation: Donation{
				NgoID:     1,
				Amount:    50.00,
				DonorName: "João Silva",
			},
			wantErr: false,
		},
		{
			name: "Invalid NgoID (zero)",
			donation: Donation{
				NgoID:     0,
				Amount:    50.00,
				DonorName: "João Silva",
			},
			wantErr: true,
		},
		{
			name: "Invalid NgoID (negative)",
			donation: Donation{
				NgoID:     -5,
				Amount:    50.00,
				DonorName: "João Silva",
			},
			wantErr: true,
		},
		{
			name: "Invalid Amount (negative)",
			donation: Donation{
				NgoID:     1,
				Amount:    -10.00,
				DonorName: "João Silva",
			},
			wantErr: true,
		},
		{
			name: "Invalid Amount (zero)",
			donation: Donation{
				NgoID:     1,
				Amount:    0,
				DonorName: "João Silva",
			},
			wantErr: true,
		},
		{
			name: "Invalid DonorName (empty)",
			donation: Donation{
				NgoID:     1,
				Amount:    50.00,
				DonorName: "   ",
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.donation.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestLivenessHandler(t *testing.T) {
	app := &App{}
	req, err := http.NewRequest("GET", "/health/live", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(app.LivenessHandler)
	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("LivenessHandler retornou status incorreto: obteve %v esperado %v", status, http.StatusOK)
	}

	expected := `{"status":"alive","service":"donation-service"}`
	if rr.Body.String() != expected {
		t.Errorf("LivenessHandler corpo da resposta inesperado: obteve %v esperado %v", rr.Body.String(), expected)
	}
}

func TestReadinessHandlerWithoutDB(t *testing.T) {
	app := &App{DB: nil}
	req, err := http.NewRequest("GET", "/health/ready", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(app.ReadinessHandler)
	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusServiceUnavailable {
		t.Errorf("ReadinessHandler sem DB retornou status incorreto: obteve %v esperado %v", status, http.StatusServiceUnavailable)
	}
}

func TestDonationHandlerInvalidMethod(t *testing.T) {
	app := &App{}
	req, err := http.NewRequest("DELETE", "/donations", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(app.DonationHandler)
	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusMethodNotAllowed {
		t.Errorf("DonationHandler DELETE retornou status incorreto: obteve %v esperado %v", status, http.StatusMethodNotAllowed)
	}
}

func TestDonationHandlerInvalidJSON(t *testing.T) {
	app := &App{}
	body := bytes.NewBufferString("{ invalid json }")
	req, err := http.NewRequest("POST", "/donations", body)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(app.DonationHandler)
	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusBadRequest {
		t.Errorf("DonationHandler com JSON invalido retornou status incorreto: obteve %v esperado %v", status, http.StatusBadRequest)
	}
}

func TestDonationHandlerValidationError(t *testing.T) {
	app := &App{}
	// Invalid payload: amount <= 0
	body := bytes.NewBufferString(`{"ngo_id": 1, "amount": -50.0, "donor_name": "Maria"}`)
	req, err := http.NewRequest("POST", "/donations", body)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(app.DonationHandler)
	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusUnprocessableEntity {
		t.Errorf("DonationHandler com payload invalido retornou status incorreto: obteve %v esperado %v", status, http.StatusUnprocessableEntity)
	}

	if !strings.Contains(rr.Body.String(), "amount deve ser maior que zero") {
		t.Errorf("Mensagem de erro esperada nao encontrada na resposta: %v", rr.Body.String())
	}
}

func TestMetricsEndpoint(t *testing.T) {
	app := &App{}
	// Call instrumented handler once to populate metrics
	handlerFunc := app.instrumentHandler("test", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	testReq, _ := http.NewRequest("GET", "/test", nil)
	testRr := httptest.NewRecorder()
	handlerFunc.ServeHTTP(testRr, testReq)

	req, err := http.NewRequest("GET", "/metrics", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := promhttp.Handler()
	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Prometheus /metrics retornou status incorreto: obteve %v esperado %v", status, http.StatusOK)
	}

	body := rr.Body.String()
	if !strings.Contains(body, "http_requests_total") || !strings.Contains(body, "go_goroutines") {
		t.Errorf("Metricas Prometheus essenciais ausentes na resposta do /metrics: %s", body)
	}
}
