"use client";
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  CartesianGrid,
  XAxis,
  YAxis,
  Tooltip,
  BarChart,
  Bar,
} from "recharts";
export function Trends({
  data,
  bar = false,
}: {
  data: { date: string; reports: number }[];
  bar?: boolean;
}) {
  if (!data.length)
    return (
      <div className="chart-empty">
        <div className="chart-grid" />
        <p>No report history yet</p>
        <small>Trends will use actual submission records.</small>
      </div>
    );
  return (
    <div style={{ width: "100%", height: 290 }}>
      <ResponsiveContainer>
        {bar ? (
          <BarChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="date" tick={{fontSize:14}} minTickGap={24}/>
            <YAxis allowDecimals={false} tick={{fontSize:14}} width={42}/>
            <Tooltip contentStyle={{fontSize:15,borderRadius:8}}/>
            <Bar dataKey="reports" fill="#078443" radius={[5, 5, 0, 0]} />
          </BarChart>
        ) : (
          <AreaChart data={data}>
            <defs>
              <linearGradient id="report-fill" x1="0" x2="0" y1="0" y2="1">
                <stop offset="0%" stopColor="#078443" stopOpacity={0.25} />
                <stop offset="100%" stopColor="#078443" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" vertical={false} />
            <XAxis dataKey="date" tick={{fontSize:14}} minTickGap={24}/>
            <YAxis allowDecimals={false} tick={{fontSize:14}} width={42}/>
            <Tooltip contentStyle={{fontSize:15,borderRadius:8}}/>
            <Area
              dataKey="reports"
              stroke="#078443"
              fill="url(#report-fill)"
              strokeWidth={2}
            />
          </AreaChart>
        )}
      </ResponsiveContainer>
    </div>
  );
}
