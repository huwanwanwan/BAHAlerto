import Module from "../[module]/page";

export default function DashboardPage() {
  return Module({
    params: Promise.resolve({ module: "dashboard" }),
    searchParams: Promise.resolve({}),
  });
}

