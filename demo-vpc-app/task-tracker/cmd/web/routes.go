package main

import (
	"net/http"
)

func (app *appConfig) routes() http.Handler {
	mux := http.NewServeMux()

	fileServer := http.FileServer(http.Dir("./ui/static/"))
	mux.Handle("GET /static/", http.StripPrefix("/static", fileServer))

	mux.HandleFunc("GET /{$}", app.home)
	mux.HandleFunc("POST /task/create", app.taskCreatePost)
	mux.HandleFunc("POST /task/toggle/{id}", app.taskToggleComplete)
	mux.HandleFunc("POST /task/delete/{id}", app.taskDelete)

	return app.recoverPanic(app.logRequest(commonHeaders(mux)))
}
