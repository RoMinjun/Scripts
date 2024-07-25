package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
)

type HokStatus struct {
	Payload struct {
		Open int `json:"open"`
	} `json:"payload"`
}

func main() {
	// Scrape json file from website
	resp, err := http.Get("https://romin.dev/api/ishethokalopen")
	if err != nil {
		fmt.Println("Error fetching the API:", err)
		return
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		fmt.Println("Error reading response body:", err)
		return
	}

	var hokStatus HokStatus
	if err := json.Unmarshal(body, &hokStatus); err != nil {
		fmt.Println("Error unmarshalling JSON:", err)
		return
	}

	// Get hok open status
	openStatus := hokStatus.Payload.Open

	// Check for open status for webhook
	status := "dicht"
	if openStatus != 0 {
		status = "open"
	}

	// Setting file path
	filePath := "/path/to/openstatus.txt"

	// Read current status from file
	currentStatusBytes, err := ioutil.ReadFile(filePath)
	if err != nil {
		fmt.Println("Error reading file:", err)
		return
	}
	currentStatus := string(currentStatusBytes)

	if status == currentStatus {
		return
	}

	// Write status to file if there's a difference
	if err := ioutil.WriteFile(filePath, []byte(status), 0644); err != nil {
		fmt.Println("Error writing to file:", err)
		return
	}

	// Webhook configs
	webhookURL := "https://discord.com/api/webhooks/[REDACTED]"
	message := fmt.Sprintf("Het hok is **%s**", status)

	// Running webhook if status has changed
	_, err = http.PostForm(webhookURL, map[string][]string{
		"content": {message},
	})
	if err != nil {
		fmt.Println("Error posting to webhook:", err)
		return
	}
}
