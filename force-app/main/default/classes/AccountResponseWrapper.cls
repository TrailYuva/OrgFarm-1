public class AccountResponseWrapper {
    public Boolean success;
    public Object data;
    public String message;
    public List<ErrorDetail> errors;
    public String timestamp;
    public String requestId;
    public Map<String, Object> pagination;

    public AccountResponseWrapper() {
        this.success = false;
        this.errors = new List<ErrorDetail>();
        this.timestamp = Datetime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        this.requestId = generateRequestId();
        this.pagination = new Map<String, Object>();
    }

    public static String generateRequestId() {
        return 'req_' + String.valueOf(Datetime.now().getTime());
    }

    public class ErrorDetail {
        public String code;
        public String message;
        public String field;
        public String details;

        public ErrorDetail() {}
        public ErrorDetail(String code, String message) {
            this.code = code;
            this.message = message;
        }
        public ErrorDetail(String code, String message, String field) {
            this(code, message);
            this.field = field;
        }
        public ErrorDetail(String code, String message, String field, String details) {
            this(code, message, field);
            this.details = details;
        }
    }
}
