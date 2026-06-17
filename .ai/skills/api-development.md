# Skill Manual: API Development

Best practices and standards for implementing REST and internal communication APIs.

---

## 🎯 Purpose
To guide the creation of secure, predictable, and performant back-end REST APIs and webhook receivers linking Web3 nodes, database stores, and mobile channels.

---

## 💡 Best Practices

* **RESTful Path Schemas:** Use clear plural nouns for resources (e.g. `/api/v1/farmers`, `/api/v1/loans`).
* **Zod Validation Middleware:** Validate request parameters, query variables, and request body elements before hitting controller logic.
* **Standard HTTP Codes:**
  * `200 OK` / `201 Created` / `202 Accepted`
  * `400 Bad Request` (Validation errors)
  * `401 Unauthorized` (Authentication missing)
  * `403 Forbidden` (Insufficient role access)
  * `404 Not Found` (Resource missing)
  * `500 Internal Error` (Unexpected server crashes)
* **Global Error Middleware:** Trap all uncaught exceptions in custom wrapper middlewares to prevent server termination and info leaks.

---

## 🛑 Constraints

* **Rate Limiting:** Enforce request volume capping on public endpoints (e.g., maximum 100 requests per 15 minutes per IP).
* **Versioning:** Keep API routes versioned (always prefix endpoints with `/api/v1/...`).
* **Sanitized Logs:** Never log plaintext passwords, API keys, or JWT signatures.

---

## 📐 Code Conventions

* **Zod Validation Handler:**
  ```typescript
  import { Request, Response, NextFunction } from 'express';
  import { AnyZodObject } from 'zod';
  
  export const validateRequest = (schema: AnyZodObject) => 
    async (req: Request, res: Response, next: NextFunction): Promise<void> => {
      try {
        await schema.parseAsync({
          body: req.body,
          query: req.query,
          params: req.params,
        });
        next();
      } catch (error: any) {
        res.status(400).json({ status: 'error', errors: error.errors });
      }
    };
  ```

---

## ⚠️ Common Pitfalls

* **Uncaught Promise Rejections:** Forgetting to wrap asynchronous calls in `try/catch` or omitting `next(error)` inside Express middleware.
* **Silent DB Errors:** Swallowing database write failures, causing the API to return a successful code even though the transaction failed.

---

## ✅ Acceptance Criteria

1. **Standardized JSON Schema:** Every response follows a consistent model: `{ status: "success" | "error", data?: any, message?: string }`.
2. **Auto-docs generation:** OpenAPI/Swagger configurations auto-update based on route schemas.
3. **Integration Test verified:** Every endpoint has matching integration tests covering both successful states and expected error codes.
