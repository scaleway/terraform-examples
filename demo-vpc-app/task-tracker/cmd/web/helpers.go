package main

import (
	"bytes"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/go-playground/form/v4"
	"github.com/julienschmidt/httprouter"
)

func (app *appConfig) serverError(w http.ResponseWriter, r *http.Request, err error) {
	var (
		method = r.Method
		uri    = r.URL.RequestURI()
	)

	app.logger.Error(err.Error(), "method", method, "uri", uri)
	http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
}

func (app *appConfig) clientError(w http.ResponseWriter, status int) {
	http.Error(w, http.StatusText(status), status)
}

func (app *appConfig) renderTemplate(w http.ResponseWriter, r *http.Request, status int, page string, data templateData) {
	ts, ok := app.templateCache[page]
	if !ok {
		err := fmt.Errorf("the template %s does not exist", page)
		app.serverError(w, r, err)
		return
	}

	buf := new(bytes.Buffer)

	if r.Header.Get("HX-Request") == "true" {
		err := ts.ExecuteTemplate(buf, "task", data)
		if err != nil {
			app.serverError(w, r, err)
			return
		}
	} else {
		err := ts.ExecuteTemplate(buf, "base", data)
		if err != nil {
			app.serverError(w, r, err)
			return
		}
	}

	w.WriteHeader(status)
	buf.WriteTo(w)
}

func (app *appConfig) newTemplateData(r *http.Request) templateData {
	return templateData{
		CurrentYear: time.Now().Year(),
	}
}

func (app *appConfig) decodeForm(r *http.Request, dst any) error {
	err := r.ParseForm()
	if err != nil {
		return err
	}

	err = app.formDecoder.Decode(dst, r.PostForm)
	if err != nil {
		var invalidDecoderError *form.InvalidDecoderError

		if errors.As(err, &invalidDecoderError) {
			panic(err)
		}

		return err
	}

	return nil
}

func (app *appConfig) readIDParam(r *http.Request) (int, error) {
	params := httprouter.ParamsFromContext(r.Context())

	idStr := params.ByName("id")
	id, err := strconv.Atoi(idStr)
	if err != nil || id < 1 {
		return 0, errors.New("invalid id parameter")
	}

	return id, nil
}
