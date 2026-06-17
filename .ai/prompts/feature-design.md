# Prompt Blueprint: Feature Design

Use this prompt to guide the AI when sketching technical design options for a new feature.

---

## 🤖 Instructions to Architect

Please design a technical implementation plan for the requested feature. Your design must align with BikkoChain's architecture and conform to the following:

1. **Context Extraction:** Review [.ai/context/product.md](file:///c:/Users/user/Desktop/bikkofarms-platform/.ai/context/product.md) and [.ai/context/architecture.md](file:///c:/Users/user/Desktop/bikkofarms-platform/.ai/context/architecture.md).
2. **Breakdown Structure:**
   * **Database Changes:** What tables, columns, or relationship fields are added/modified?
   * **Smart Contract Changes:** What Solidity structures are required? What events are emitted?
   * **API Routes:** Detail routes, request bodies, query options, and Zod schemas.
   * **UI Component Tree:** What Next.js Server Components and client interaction nodes are built?
3. **Risks & Mitigation:** What performance, latency, or network connectivity constraints exist for this feature? How do we mitigate them?
4. **Testing Checklist:** What unit and integration test strategies will check this logic?

Provide the technical output matching the schema in [.ai/templates/adr-template.md](file:///c:/Users/user/Desktop/bikkofarms-platform/.ai/templates/adr-template.md).
