enum PagOperationType { CREATE, READ, UPDATE, DELETE, LIST }

class MdlPagOperation {
  PagOperationType operation;

  MdlPagOperation({
    required this.operation,
  });
}
