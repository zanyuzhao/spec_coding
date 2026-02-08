import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Spec App",
  description: "Spec-driven fullstack",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="zh-CN">
      <body className="min-h-screen antialiased">{children}</body>
    </html>
  );
}
