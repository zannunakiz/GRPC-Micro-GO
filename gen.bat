protoc ^
  --proto_path=protobuf protobuf/orders.proto ^
  --go_out=services/common/genproto/orders --go_opt=paths=source_relative ^
  --go-grpc_out=services/common/genproto/orders ^
  --go-grpc_opt=paths=source_relative