# GRPC Microservices

A Microservices architecture built with **Go** and **gRPC**.

```text
[ Client / Postman ]
         │
         │  HTTP / REST (JSON)
         ▼
 ┌─────────────────┐
 │  Orders Service │  (HTTP Gateway & gRPC Client)
 └────────┬────────┘
          │
          │  gRPC / Protobuf
          ▼
 ┌─────────────────┐
 │ Kitchen Service │  (gRPC Server)
 └─────────────────┘

```

---

## 🚀 Quick Start

### 1. Run Orders Service

The **Orders** service server is ready to run. Executing the service will start the HTTP/gRPC server instance.

Open your terminal and run:

```bash
make run-orders

```

---

## 📮 API Testing

A pre-configured Postman collection is available in `postman-collection.json` in the root repository. Import this file directly into Postman to start testing API requests.