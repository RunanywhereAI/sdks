import Testing
@testable import RunAnywhere

@Test func test_run_any_where() async throws {
    let runAnywhere = RunAnywhere()
    let result = await runAnywhere.runAnywhere()
    #expect(result == "Hello, World!")
}
