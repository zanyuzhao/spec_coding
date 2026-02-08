import { SpecList } from "@/components/spec_list";

export default function Home() {
  return (
    <main className="container mx-auto p-6">
      <h1 className="text-2xl font-semibold mb-4">Spec 列表</h1>
      <SpecList />
    </main>
  );
}
