"use client";

import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";

interface SpecItem {
  id: string;
  title: string;
  status: string;
}

export function SpecList() {
  const [data, setData] = useState<SpecItem[] | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    fetch("/api/spec/list")
      .then((res) => res.json())
      .then((json: { ok: boolean; data?: SpecItem[]; error?: string }) => {
        if (cancelled) return;
        if (!json.ok) {
          setError(json.error ?? "请求失败");
          setData(null);
        } else {
          setData(json.data ?? []);
        }
      })
      .catch((e) => {
        if (!cancelled) setError(e instanceof Error ? e.message : "网络错误");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  if (loading) {
    return <p className="text-muted-foreground">加载中...</p>;
  }
  if (error) {
    return (
      <div className="rounded-md border border-destructive/50 bg-destructive/10 p-4">
        <p className="text-destructive">错误：{error}</p>
        <Button variant="outline" size="sm" onClick={() => window.location.reload()} className="mt-2">
          重试
        </Button>
      </div>
    );
  }
  if (!data?.length) {
    return <p className="text-muted-foreground">暂无 Spec</p>;
  }
  return (
    <ul className="space-y-2">
      {data.map((item) => (
        <li key={item.id} className="flex items-center gap-2 rounded border px-3 py-2">
          <span className="font-medium">{item.title}</span>
          <span className="text-muted-foreground text-sm">{item.status}</span>
        </li>
      ))}
    </ul>
  );
}
