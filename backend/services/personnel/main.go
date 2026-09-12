package main

import (
	"log"
	"os"
	"time"

	"github.com/siteeksen/backend/pkg/stub"

	"github.com/gin-gonic/gin"
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

	r.GET("/health", stub.Health("personnel"))

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

func listEmployees(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "personnel")
}

func getEmployeeStats(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "personnel")
}

func getEmployee(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "personnel")
}

func createEmployee(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "personnel")
}

func updateEmployee(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "personnel")
}

func deleteEmployee(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "personnel")
}

func getEmployeePayroll(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "personnel")
}

func getEmployeeLeaves(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "personnel")
}

func listPayroll(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "personnel")
}

func generatePayroll(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "personnel")
}

func markAsPaid(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "personnel")
}

func listLeaves(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "personnel")
}

func getPendingLeaves(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "personnel")
}

func createLeave(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "personnel")
}

func approveLeave(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "personnel")
}

func rejectLeave(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "personnel")
}
