# Prompt Blueprint: Code Review

Use this prompt to guide the AI when reviewing pull requests or code diffs.

---

## 🤖 Instructions to Reviewer

Analyze the provided code changes and check them against the BikkoChain engineering standards:

1. **Rule Verification:** Check that the code satisfies [.ai/rules/agent-rules.md](file:///c:/Users/user/Desktop/bikkofarms-platform/.ai/rules/agent-rules.md).
2. **Security Checks:**
   * Are database queries parameterized? (No SQL injections)
   * Are smart contract functions checks-effects-interactions compliant? (No reentrancy)
   * Are access modifiers appropriately placed? (No unauthorized state writes)
3. **Type Safety:** Ensure TypeScript types are explicitly declared without using `any`.
4. **Performance:** Highlight N+1 query patterns, lack of indexing on query parameters, or heavy client-side imports.
5. **a11y Compliance:** Verify HTML structure is semantic and accessible.
6. **Test Check:** Are tests included for new features? Do tests mock external integrations?

Format your review outputs with:
* **Critical issues:** Blockers that must be fixed.
* **Suggestions:** Quality improvements or performance gains.
* **Positives:** Code patterns that were well executed.
