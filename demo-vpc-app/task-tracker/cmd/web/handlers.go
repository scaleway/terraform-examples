package main

import (
	"net/http"
	"strconv"

	"github.com/scaleway/terraform-/demo-vpc-app/internal/validator"
)

type taskForm struct {
	Content             string `form:"content"`
	validator.Validator `form:"-"`
}

func (app *appConfig) home(w http.ResponseWriter, r *http.Request) {
	tasks, err := app.tasks.GetAll()
	if err != nil {
		app.serverError(w, r, err)
		return
	}

	data := app.newTemplateData(r)
	data.Tasks = tasks
	data.Form = taskForm{}

	app.renderTemplate(w, r, http.StatusOK, "home.tmpl", data)
}

func (app *appConfig) taskCreatePost(w http.ResponseWriter, r *http.Request) {
	var form taskForm

	err := app.decodeForm(r, &form)
	if err != nil {
		app.clientError(w, http.StatusBadRequest)
		return
	}

	form.CheckField(validator.NotBlank(form.Content), "content", "This field cannot be blank")

	if !form.Valid() {
		http.Redirect(w, r, "/", http.StatusSeeOther)
		return
	}

	id, err := app.tasks.Insert(form.Content)
	if err != nil {
		app.serverError(w, r, err)
		return
	}

	if r.Header.Get("HX-Request") == "true" {
		task, err := app.tasks.Get(id)
		if err != nil {
			app.serverError(w, r, err)
			return
		}
		data := app.newTemplateData(r)
		data.Task = task
		app.renderTemplate(w, r, http.StatusOK, "task.tmpl", data)
		return
	}

	http.Redirect(w, r, "/", http.StatusSeeOther)
}

func (app *appConfig) taskToggleComplete(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil || id < 1 {
		http.NotFound(w, r)
		return
	}

	err = app.tasks.Complete(id)
	if err != nil {
		app.serverError(w, r, err)
		return
	}

	if r.Header.Get("HX-Request") == "true" {
		task, err := app.tasks.Get(id)
		if err != nil {
			app.serverError(w, r, err)
			return
		}
		data := app.newTemplateData(r)
		data.Task = task
		app.renderTemplate(w, r, http.StatusOK, "task.tmpl", data)
		return
	}

	http.Redirect(w, r, "/", http.StatusSeeOther)
}

func (app *appConfig) taskDelete(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil || id < 1 {
		http.NotFound(w, r)
		return
	}

	err = app.tasks.Delete(id)
	if err != nil {
		app.serverError(w, r, err)
		return
	}

	if r.Header.Get("HX-Request") == "true" {
		w.WriteHeader(http.StatusOK)
		return
	}

	http.Redirect(w, r, "/", http.StatusSeeOther)
}
