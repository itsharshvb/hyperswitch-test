use utoipa::ToSchema;

/// Test - New Endpoint
///
/// This is a test endpoint added to verify API compatibility workflow detection of new endpoints.
#[utoipa::path(
    get,
    path = "/test/new-endpoint",
    responses(
        (status = 200, description = "Test endpoint response", body = TestResponse)
    ),
    tag = "Testing",
    operation_id = "Test New Endpoint Detection",
    security(("api_key" = []))
)]
pub async fn test_new_endpoint() {}

#[derive(ToSchema)]
pub struct TestResponse {
    /// Test message
    pub message: String,
}