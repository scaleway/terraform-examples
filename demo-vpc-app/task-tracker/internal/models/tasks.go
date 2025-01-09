package models

import (
	"database/sql"
	"errors"
	"time"
)

var ErrNoRecord = errors.New("models: no matching record found")

type Task struct {
	ID        int
	Content   string
	Created   time.Time
	Completed bool
}

type TaskModel struct {
	DB *sql.DB
}

func (m *TaskModel) Insert(content string) (int, error) {
	query := `
        INSERT INTO tasks (content, created, completed)
        VALUES ($1, NOW() AT TIME ZONE 'UTC', FALSE)
        RETURNING id`

	var id int
	err := m.DB.QueryRow(query, content).Scan(&id)
	if err != nil {
		return 0, err
	}

	return id, nil
}

func (m *TaskModel) Get(id int) (Task, error) {
	query := `SELECT id, content, created, completed FROM tasks WHERE id = $1`

	var t Task
	err := m.DB.QueryRow(query, id).Scan(&t.ID, &t.Content, &t.Created, &t.Completed)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return Task{}, ErrNoRecord
		} else {
			return Task{}, err
		}
	}

	return t, nil
}

func (m *TaskModel) GetAll() ([]Task, error) {
	query := `SELECT id, content, created, completed FROM tasks ORDER BY id DESC`

	rows, err := m.DB.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tasks []Task

	for rows.Next() {
		var t Task
		err := rows.Scan(&t.ID, &t.Content, &t.Created, &t.Completed)
		if err != nil {
			return nil, err
		}
		tasks = append(tasks, t)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return tasks, nil
}

func (m *TaskModel) Complete(id int) error {
	query := `UPDATE tasks SET completed = NOT completed WHERE id = $1`

	_, err := m.DB.Exec(query, id)
	return err
}

func (m *TaskModel) Delete(id int) error {
	query := `DELETE FROM tasks WHERE id = $1`

	_, err := m.DB.Exec(query, id)
	return err
}
