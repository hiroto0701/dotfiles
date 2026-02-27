# TypeScript Rules

TypeScript プロジェクト固有のルール。

---

## Type Safety

### Strict Mode Required

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "useUnknownInCatchVariables": true,
    "alwaysStrict": true
  }
}
```

### No `any` Type

```typescript
// ❌ Bad: any type
function process(data: any): any {
  return data.value;
}

// ✅ Good: Explicit types
function process(data: UserInput): ProcessedData {
  return { value: data.value };
}

// ✅ Good: Generic when type is truly unknown
function process<T extends { value: unknown }>(data: T): T['value'] {
  return data.value;
}
```

### Prefer `unknown` over `any`

```typescript
// ❌ Bad
function parseJSON(json: string): any {
  return JSON.parse(json);
}

// ✅ Good
function parseJSON(json: string): unknown {
  return JSON.parse(json);
}

// Usage with type guard
const data = parseJSON(jsonString);
if (isUserData(data)) {
  console.log(data.email);
}
```

---

## Type Definitions

### Interface vs Type

```typescript
// Use interface for object shapes (extensible)
interface User {
  id: string;
  email: string;
}

// Use type for unions, primitives, computed types
type Status = 'pending' | 'active' | 'inactive';
type UserId = string;
type UserWithStatus = User & { status: Status };
```

### Prefer Type Inference

```typescript
// ❌ Redundant type annotation
const name: string = 'John';
const users: User[] = [{ id: '1', email: 'a@b.com' }];

// ✅ Let TypeScript infer
const name = 'John';
const users = [{ id: '1', email: 'a@b.com' }] satisfies User[];
```

### Const Assertions

```typescript
// ❌ Mutable
const config = {
  api: 'https://api.example.com',
  timeout: 5000,
};
// type: { api: string; timeout: number }

// ✅ Immutable and narrow
const config = {
  api: 'https://api.example.com',
  timeout: 5000,
} as const;
// type: { readonly api: "https://api.example.com"; readonly timeout: 5000 }
```

---

## Null Handling

### Use Optional Chaining

```typescript
// ❌ Verbose null checks
const street = user && user.address && user.address.street;

// ✅ Optional chaining
const street = user?.address?.street;
```

### Use Nullish Coalescing

```typescript
// ❌ Falsy check (treats 0 and '' as falsy)
const value = input || 'default';

// ✅ Nullish coalescing (only null/undefined)
const value = input ?? 'default';
```

### Prefer `undefined` over `null`

```typescript
// ✅ Consistent with TypeScript's optional properties
interface User {
  email: string;
  phone?: string; // undefined when not set
}

// ❌ Avoid mixing null and undefined
interface User {
  email: string;
  phone: string | null; // Avoid unless API requires null
}
```

---

## Generics

### Meaningful Generic Names

```typescript
// ❌ Single letter (except simple cases)
function process<T, U, V>(a: T, b: U): V {}

// ✅ Descriptive names
function process<TInput, TOutput, TContext>(
  input: TInput,
  context: TContext
): TOutput {}
```

### Constrained Generics

```typescript
// ❌ Too permissive
function getId<T>(obj: T): string {
  return obj.id; // Error: Property 'id' does not exist
}

// ✅ Constrained
function getId<T extends { id: string }>(obj: T): string {
  return obj.id;
}
```

### Default Type Parameters

```typescript
// Provide sensible defaults
interface ApiResponse<TData = unknown, TError = Error> {
  data?: TData;
  error?: TError;
  status: number;
}

// Usage
const response: ApiResponse<User> = await fetchUser();
```

---

## Enums

### Prefer String Enums

```typescript
// ❌ Number enums (less readable in logs/debugging)
enum Status {
  Pending,   // 0
  Active,    // 1
  Inactive,  // 2
}

// ✅ String enums
enum Status {
  Pending = 'pending',
  Active = 'active',
  Inactive = 'inactive',
}
```

### Consider Union Types

```typescript
// ✅ Often simpler than enums
type Status = 'pending' | 'active' | 'inactive';

// Benefits: No runtime overhead, better tree-shaking
```

---

## Functions

### Explicit Return Types for Public APIs

```typescript
// ❌ Implicit return type (internal is OK)
export function createUser(input: UserInput) {
  return { id: generateId(), ...input };
}

// ✅ Explicit return type (public API)
export function createUser(input: UserInput): User {
  return { id: generateId(), ...input };
}
```

### Function Overloads

```typescript
// Use overloads for complex type relationships
function format(value: string): string;
function format(value: number): string;
function format(value: Date): string;
function format(value: string | number | Date): string {
  if (typeof value === 'string') return value;
  if (typeof value === 'number') return value.toString();
  return value.toISOString();
}
```

### Arrow Functions for Callbacks

```typescript
// ✅ Arrow functions preserve `this` and are concise
const doubled = numbers.map(n => n * 2);

// ✅ Use regular functions for methods that need `this`
class Calculator {
  multiply(n: number): number {
    return n * this.factor;
  }
}
```

---

## Modules

### Named Exports Preferred

```typescript
// ❌ Default export (harder to refactor, inconsistent naming)
export default class UserService {}

// ✅ Named export
export class UserService {}
export function createUser() {}
```

### Barrel Exports

```typescript
// src/services/index.ts
export { UserService } from './user.service';
export { OrderService } from './order.service';
export type { UserInput, OrderInput } from './types';

// Usage
import { UserService, OrderService } from './services';
```

### Import Order

```typescript
// 1. External packages
import { useState, useEffect } from 'react';
import { z } from 'zod';

// 2. Internal aliases (@/)
import { UserService } from '@/services';
import { Button } from '@/components';

// 3. Relative imports
import { formatDate } from './utils';
import type { UserProps } from './types';
```

---

## Error Handling

### Typed Errors

```typescript
class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number = 500,
    public readonly details?: Record<string, unknown>
  ) {
    super(message);
    this.name = this.constructor.name;
  }
}

class ValidationError extends AppError {
  constructor(message: string, details?: Record<string, unknown>) {
    super(message, 'VALIDATION_ERROR', 400, details);
  }
}
```

### Result Type Pattern

```typescript
type Result<T, E = Error> =
  | { success: true; data: T }
  | { success: false; error: E };

function divide(a: number, b: number): Result<number, string> {
  if (b === 0) {
    return { success: false, error: 'Division by zero' };
  }
  return { success: true, data: a / b };
}

// Usage
const result = divide(10, 2);
if (result.success) {
  console.log(result.data); // Type: number
} else {
  console.error(result.error); // Type: string
}
```

---

## Async/Await

### Always Handle Errors

```typescript
// ❌ Unhandled promise rejection
async function fetchUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  return response.json();
}

// ✅ Proper error handling
async function fetchUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  if (!response.ok) {
    throw new AppError(`Failed to fetch user: ${response.status}`, 'FETCH_ERROR');
  }
  return response.json();
}
```

### Avoid Async in Constructors

```typescript
// ❌ Async constructor (not possible, leads to workarounds)
class UserService {
  constructor() {
    await this.init(); // Error
  }
}

// ✅ Factory pattern
class UserService {
  private constructor(private db: Database) {}

  static async create(): Promise<UserService> {
    const db = await Database.connect();
    return new UserService(db);
  }
}
```

---

## Type Guards

### User-Defined Type Guards

```typescript
function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'email' in value
  );
}

// Usage
const data: unknown = await fetchData();
if (isUser(data)) {
  console.log(data.email); // Type: User
}
```

### Discriminated Unions

```typescript
type ApiResponse =
  | { status: 'success'; data: User }
  | { status: 'error'; message: string }
  | { status: 'loading' };

function handleResponse(response: ApiResponse) {
  switch (response.status) {
    case 'success':
      return response.data; // Type: User
    case 'error':
      throw new Error(response.message); // Type: string
    case 'loading':
      return null;
  }
}
```

---

## Utility Types

### Common Patterns

```typescript
// Partial: Make all properties optional
type PartialUser = Partial<User>;

// Required: Make all properties required
type RequiredUser = Required<User>;

// Pick: Select specific properties
type UserEmail = Pick<User, 'email'>;

// Omit: Exclude specific properties
type UserWithoutPassword = Omit<User, 'password'>;

// Record: Create object type with specific key/value
type StatusMap = Record<Status, number>;

// Extract: Extract union members
type ActiveStatus = Extract<Status, 'active' | 'pending'>;

// Exclude: Exclude union members
type InactiveStatus = Exclude<Status, 'active'>;
```

---

_TypeScript Rules: 型安全 × 可読性 × 保守性_
