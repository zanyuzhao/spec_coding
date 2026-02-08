import { NextResponse } from "next/server";

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://127.0.0.1:8000";

export async function GET(): Promise<NextResponse> {
  try {
    const res = await fetch(`${API_BASE}/api/spec/list`, { cache: "no-store" });
    const json = await res.json();
    return NextResponse.json(json);
  } catch (e) {
    return NextResponse.json({
      ok: false,
      data: null,
      error: e instanceof Error ? e.message : "Backend unreachable",
    });
  }
}
