package main

import (
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type Employee struct {
	ID         string    `json:"id"`
	PropertyID string    `json:"property_id"`
	FirstName  string    `json:"first_name"`
	LastName   string    `json:"last_name"`
	FullName   string    `json:"full_name,omitempty"`
	TCNumber   string    `json:"tc_number,omitempty"`
	Department string    `json:"department"`
	Position   string    `json:"position"`
	Phone      string    `json:"phone,omitempty"`
	Email      string    `json:"email,omitempty"`
	HireDate   string    `json:"hire_date"`
	BaseSalary float64   `json:"base_salary,omitempty"`
	Status     string    `json:"status"` // ACTIVE, ON_LEAVE, TERMINATED
	PhotoURL   string    `json:"photo_url,omitempty"`
	CreatedAt  time.Time `json:"created_at"`
}

type PayrollRecord struct {
	ID           string     `json:"id"`
	EmployeeID   string     `json:"employee_id"`
	EmployeeName string     `json:"employee_name,omitempty"`
	Period       string     `json:"period"` // 2026-01
	BaseSalary   float64    `json:"base_salary"`
	Overtime     float64    `json:"overtime"`
	Bonus        float64    `json:"bonus"`
	Deductions   float64    `json:"deductions"`
	NetSalary    float64    `json:"net_salary"`
	Status       string     `json:"status"` // PENDING, PAID
	PaidAt       *time.Time `json:"paid_at,omitempty"`
}

type LeaveRequest struct {
	ID           string    `json:"id"`
	EmployeeID   string    `json:"employee_id"`
	EmployeeName string    `json:"employee_name,omitempty"`
	LeaveType    string    `json:"leave_type"` // ANNUAL, SICK, UNPAID
	StartDate    string    `json:"start_date"`
	EndDate      string    `json:"end_date"`
	Days         int       `json:"days"`
	Status       string    `json:"status"` // PENDING, APPROVED, REJECTED
	Notes        string    `json:"notes,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
}

func main() {
	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy", "service": "personnel"})
	})

	v1 := r.Group("/api/v1")
	{
		employees := v1.Group("/employees")
		{
			employees.GET("", listEmployees)
			employees.GET("/stats", getEmployeeStats)
			employees.GET("/:id", getEmployee)
			employees.POST("", createEmployee)
			employees.PUT("/:id", updateEmployee)
			employees.DELETE("/:id", deleteEmployee)
			employees.GET("/:id/payroll", getEmployeePayroll)
			employees.GET("/:id/leaves", getEmployeeLeaves)
		}

		payroll := v1.Group("/payroll")
		{
			payroll.GET("", listPayroll)
			payroll.POST("/generate", generatePayroll)
			payroll.POST("/:id/pay", markAsPaid)
		}

		leaves := v1.Group("/leaves")
		{
			leaves.GET("", listLeaves)
			leaves.GET("/pending", getPendingLeaves)
			leaves.POST("", createLeave)
			leaves.POST("/:id/approve", approveLeave)
			leaves.POST("/:id/reject", rejectLeave)
		}
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8100"
	}
	log.Printf("Personnel Service starting on port %s", port)
	r.Run(":" + port)
}

func listEmployees(c *gin.Context) {
	employees := []Employee{
		{ID: uuid.New().String(), FirstName: "Hasan", LastName: "Güvenlik", FullName: "Hasan Güvenlik", Department: "Güvenlik", Position: "Güvenlik Görevlisi", HireDate: "2022-03-15", BaseSalary: 18000, Status: "ACTIVE", CreatedAt: time.Now()},
		{ID: uuid.New().String(), FirstName: "Fatma", LastName: "Temizlik", FullName: "Fatma Temizlik", Department: "Temizlik", Position: "Temizlik Personeli", HireDate: "2023-06-01", BaseSalary: 14000, Status: "ACTIVE", CreatedAt: time.Now()},
		{ID: uuid.New().String(), FirstName: "Mehmet", LastName: "Bakım", FullName: "Mehmet Bakım", Department: "Teknik", Position: "Teknik Personel", HireDate: "2021-01-10", BaseSalary: 20000, Status: "ACTIVE", CreatedAt: time.Now()},
	}
	c.JSON(http.StatusOK, gin.H{"employees": employees, "total": len(employees)})
}

func getEmployeeStats(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"total_employees": 8, "active": 7, "on_leave": 1, "monthly_payroll": 125000.00, "pending_leaves": 2})
}

func getEmployee(c *gin.Context) {
	c.JSON(http.StatusOK, Employee{ID: c.Param("id"), FullName: "Hasan Güvenlik", Status: "ACTIVE"})
}

func createEmployee(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": uuid.New().String(), "message": "Personel oluşturuldu"})
}

func updateEmployee(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id"), "message": "Personel güncellendi"})
}

func deleteEmployee(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id"), "message": "Personel silindi"})
}

func getEmployeePayroll(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"employee_id": c.Param("id"), "records": []PayrollRecord{}})
}

func getEmployeeLeaves(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"employee_id": c.Param("id"), "leaves": []LeaveRequest{}})
}

func listPayroll(c *gin.Context) {
	records := []PayrollRecord{
		{ID: uuid.New().String(), EmployeeName: "Hasan Güvenlik", Period: "2026-01", BaseSalary: 18000, Overtime: 1500, NetSalary: 19500, Status: "PAID"},
		{ID: uuid.New().String(), EmployeeName: "Fatma Temizlik", Period: "2026-01", BaseSalary: 14000, NetSalary: 14000, Status: "PAID"},
	}
	c.JSON(http.StatusOK, gin.H{"records": records})
}

func generatePayroll(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"period": "2026-02", "records_generated": 8, "total_amount": 125000.00})
}

func markAsPaid(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id"), "status": "PAID", "paid_at": time.Now()})
}

func listLeaves(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"leaves": []LeaveRequest{}})
}

func getPendingLeaves(c *gin.Context) {
	leaves := []LeaveRequest{
		{ID: uuid.New().String(), EmployeeName: "Fatma Temizlik", LeaveType: "ANNUAL", StartDate: "2026-02-15", EndDate: "2026-02-20", Days: 5, Status: "PENDING", CreatedAt: time.Now()},
	}
	c.JSON(http.StatusOK, gin.H{"leaves": leaves, "count": len(leaves)})
}

func createLeave(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": uuid.New().String(), "status": "PENDING", "message": "İzin talebi oluşturuldu"})
}

func approveLeave(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id"), "status": "APPROVED", "message": "İzin onaylandı"})
}

func rejectLeave(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id"), "status": "REJECTED", "message": "İzin reddedildi"})
}
