db = db.getSiblingDB('todo-app');

db.createCollection('todos');

db.todos.insertMany([
  { text: "Laercio e um excelente professor", completed: false },
  { text: "Estudar Cloud", completed: true },
  { text: "Fazer exercicios da UA", completed: false },
]);
