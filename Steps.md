# Steps.md — Rebuild This Project From Scratch

Project: Go GRPC microservices monorepo (Orders + Kitchen), sharing generated protobuf code in `services/common/genproto`.

## Architecture Overview

```
protobuf/orders.proto                 -> single source of truth (contracts)
services/common/genproto/orders/      -> generated pb.go files (shared by all services)
services/common/util/util.go          -> JSON helpers
services/orders/                      -> Order service (HTTP :8000 + gRPC :9000)
services/kitchen/                     -> Kitchen service (gRPC client of orders)  [to be added]
Makefile, gen.bat, go.mod
```

Flow: client → orders HTTP (POST /orders) or gRPC → handler → service (in-memory slice) → response. Kitchen will call the orders gRPC server (:9000) to fetch orders and "cook" them.

## Tools to Install First

- Go (1.25+)
- Protocol Buffer compiler: `protoc` (check with `protoc --version`)
- Go plugins: `go install google.golang.org/protobuf/cmd/protoc-gen-go@latest` and `go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest` (both must be in PATH)
- Windows: use `gen.bat`; Linux/Mac: use an equivalent Makefile target

## Step-by-Step

### 1. Init project
- `mkdir GRPC-Micro-GO && cd GRPC-Micro-GO`
- `go mod init github.com/<you>/GRPC-Micro-GO`
- Create `.gitignore`, `git init`

### 2. Install gRPC deps
- `go get google.golang.org/grpc`
- `go get google.golang.org/protobuf`

### 3. Define the protobuf contract
- Create `protobuf/orders.proto`
- Content: `proto3` syntax, `go_package` option, `OrderService` with `CreateOrder` and `GetOrders` RPCs, messages: `Order`, `CreateOrderRequest`, `CreateOrderResponse`, `GetOrdersRequest`, `GetOrderResponse`

### 4. Generate Go code
- Windows: create `gen.bat` that runs protoc with `--proto_path=protobuf`, `--go_out`/`--go-grpc_out` into `services/common/genproto/orders` with `paths=source_relative`
- Run `.\gen.bat`
- Verify: `services/common/genproto/orders/orders.pb.go` and `orders_grpc.pb.go` exist

### 5. Shared util package
- Create `services/common/util/util.go` with `WriteJSON`, `WriteError`, `ParseJSON` helpers

### 6. Orders — types (service interface)
- Create `services/orders/types/types.go`: `OrderService` interface (`CreateOrder(ctx, *orders.Order) error`, `GetOrders(ctx) []*orders.Order`)

### 7. Orders — service layer (business logic)
- Create `services/orders/service/orders.go`: in-memory `ordersDb` slice, `NewOrderService()`, `CreateOrder` appends, `GetOrders` returns slice

### 8. Orders — gRPC handler
- Create `services/orders/handler/orders/grpc.go`: `OrdersGrpcHandler` embedding `orders.UnimplementedOrderServiceServer`, constructor registers itself on the `grpc.Server`, implements `CreateOrder` and `GetOrders`

### 9. Orders — HTTP handler
- Create `services/orders/handler/orders/http.go`: `OrdersHttpHandler`, `RegisterRouter` with `POST /orders`, `CreateOrder` parses JSON body (using `CreateOrderRequest` proto message), calls service, writes JSON response

### 10. Orders — servers + main
- Create `services/orders/grpc.go`: `gRPCServer` struct, `Run()` listens on addr, `grpc.NewServer()`, registers handler, `Serve`
- Create `services/orders/http.go`: `httpServer` struct, `Run()` builds `http.NewServeMux`, registers handler, `ListenAndServe`
- Create `services/orders/main.go`: start HTTP server on `:8000` in a goroutine, then gRPC server on `:9000` (blocking)

### 11. Makefile
- Create `Makefile` with `run-orders: go run ./services/orders/...` and `run-kitchen: go run ./services/kitchen/...`

### 12. Run & verify orders
- `make run-orders` (or `go run ./services/orders/...`)
- Test HTTP: `curl -X POST localhost:8000/orders -d "{\"customerID\":1,\"productID\":2,\"quantity\":3}"` → `{"status":"success"}`
- Test gRPC: use Postman (import `postman-collection.json`) or `grpcurl -plaintext -d '{"customerID":1}' localhost:9000 orders.OrderService/GetOrders`

### 13. Kitchen service (after orders runs)
- Create `services/kitchen/main.go`: start kitchen gRPC server on `:3000`
- Create `services/kitchen/grpc.go`: same server pattern as orders
- Create `services/kitchen/handler/kitchen/grpc.go`: registers `KitchenServiceServer` (defined in a new `protobuf/kitchen.proto` + regenerate into `services/common/genproto/kitchen`)
- In kitchen handler, create a gRPC **client** that dials `localhost:9000` (`grpc.NewClient`), uses `orders.NewOrderServiceClient(conn).GetOrders(...)` to pull orders and process them
- Add a `GetOrders`-style RPC definition to kitchen's proto if needed
- `go mod tidy`, then `make run-kitchen` (with orders still running)

### 14. Finalize
- `go mod tidy`
- Write `README.md` (how to run each service)
- Commit: `git add . && git commit -m "initial grpc microservices"`
