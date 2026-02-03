import {
    Users,
    Receipt,
    TrendingUp,
    AlertCircle,
    ArrowUpRight,
    ArrowDownRight,
} from "lucide-react";

export default function DashboardPage() {
    return (
        <div className="space-y-6">
            {/* Page Header */}
            <div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                    Dashboard
                </h1>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                    Güneş Sitesi genel durumu
                </p>
            </div>

            {/* Stats Grid */}
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                <StatCard
                    title="Toplam Sakin"
                    value="124"
                    change="+3"
                    trend="up"
                    icon={Users}
                />
                <StatCard
                    title="Bu Ay Tahsilat"
                    value="₺45.600"
                    change="+12%"
                    trend="up"
                    icon={Receipt}
                />
                <StatCard
                    title="Tahsilat Oranı"
                    value="%87"
                    change="-2%"
                    trend="down"
                    icon={TrendingUp}
                />
                <StatCard
                    title="Açık Talepler"
                    value="7"
                    change="+2"
                    trend="up"
                    icon={AlertCircle}
                    trendColor="red"
                />
            </div>

            {/* Charts Row */}
            <div className="grid gap-6 lg:grid-cols-2">
                {/* Collection Chart - Bar Chart */}
                <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                    <h3 className="mb-4 text-lg font-semibold text-gray-900 dark:text-white">
                        Aylık Tahsilat
                    </h3>
                    <div className="h-64 flex items-end gap-2 pt-4">
                        {[
                            { month: 'Oca', value: 35, amount: '₺35K' },
                            { month: 'Şub', value: 42, amount: '₺42K' },
                            { month: 'Mar', value: 38, amount: '₺38K' },
                            { month: 'Nis', value: 45, amount: '₺45K' },
                            { month: 'May', value: 52, amount: '₺52K' },
                            { month: 'Haz', value: 48, amount: '₺48K' },
                            { month: 'Tem', value: 55, amount: '₺55K' },
                            { month: 'Ağu', value: 46, amount: '₺46K' },
                            { month: 'Eyl', value: 50, amount: '₺50K' },
                            { month: 'Eki', value: 58, amount: '₺58K' },
                            { month: 'Kas', value: 62, amount: '₺62K' },
                            { month: 'Ara', value: 70, amount: '₺70K' },
                        ].map((item, idx) => (
                            <div key={idx} className="flex-1 flex flex-col items-center gap-1">
                                <div className="text-xs text-gray-500">{item.amount}</div>
                                <div
                                    className="w-full bg-gradient-to-t from-blue-500 to-blue-400 rounded-t-md transition-all hover:from-blue-600 hover:to-blue-500"
                                    style={{ height: `${item.value * 2.5}px` }}
                                />
                                <div className="text-xs text-gray-500">{item.month}</div>
                            </div>
                        ))}
                    </div>
                </div>

                {/* Consumption Chart - Pie Chart */}
                <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                    <h3 className="mb-4 text-lg font-semibold text-gray-900 dark:text-white">
                        Tüketim Dağılımı
                    </h3>
                    <div className="h-64 flex items-center justify-center gap-8">
                        {/* Pie Chart */}
                        <div className="relative w-40 h-40">
                            <div
                                className="absolute inset-0 rounded-full"
                                style={{
                                    background: `conic-gradient(
                                        #3b82f6 0deg 126deg,
                                        #10b981 126deg 216deg,
                                        #f59e0b 216deg 288deg,
                                        #ef4444 288deg 360deg
                                    )`
                                }}
                            />
                            <div className="absolute inset-6 bg-white dark:bg-gray-800 rounded-full flex items-center justify-center">
                                <span className="text-sm font-semibold text-gray-700">100%</span>
                            </div>
                        </div>
                        {/* Legend */}
                        <div className="space-y-3">
                            {[
                                { label: 'Elektrik', value: '35%', color: 'bg-blue-500' },
                                { label: 'Su', value: '25%', color: 'bg-green-500' },
                                { label: 'Doğalgaz', value: '20%', color: 'bg-yellow-500' },
                                { label: 'Ortak Gider', value: '20%', color: 'bg-red-500' },
                            ].map((item, idx) => (
                                <div key={idx} className="flex items-center gap-2">
                                    <div className={`w-3 h-3 rounded-full ${item.color}`} />
                                    <span className="text-sm text-gray-600">{item.label}</span>
                                    <span className="text-sm font-semibold text-gray-900">{item.value}</span>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>
            </div>

            {/* Recent Activity */}
            <div className="grid gap-6 lg:grid-cols-2">
                {/* Recent Payments */}
                <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                    <div className="mb-4 flex items-center justify-between">
                        <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                            Son Ödemeler
                        </h3>
                        <a href="/dashboard/assessments" className="text-sm text-primary hover:underline">
                            Tümünü Gör
                        </a>
                    </div>
                    <div className="space-y-4">
                        <PaymentItem
                            name="Mehmet Demir"
                            unit="A-4"
                            amount="₺1.200"
                            time="2 saat önce"
                        />
                        <PaymentItem
                            name="Ayşe Yıldız"
                            unit="B-7"
                            amount="₺1.150"
                            time="5 saat önce"
                        />
                        <PaymentItem
                            name="Ali Kaya"
                            unit="A-12"
                            amount="₺2.300"
                            time="1 gün önce"
                        />
                    </div>
                </div>

                {/* Recent Requests */}
                <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
                    <div className="mb-4 flex items-center justify-between">
                        <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                            Son Talepler
                        </h3>
                        <a href="/dashboard/requests" className="text-sm text-primary hover:underline">
                            Tümünü Gör
                        </a>
                    </div>
                    <div className="space-y-4">
                        <RequestItem
                            title="Asansör arızası"
                            unit="Ortak Alan"
                            status="open"
                            time="1 saat önce"
                        />
                        <RequestItem
                            title="Merdiven aydınlatma"
                            unit="A Blok"
                            status="in_progress"
                            time="4 saat önce"
                        />
                        <RequestItem
                            title="Bahçe sulama"
                            unit="Ortak Alan"
                            status="resolved"
                            time="1 gün önce"
                        />
                    </div>
                </div>
            </div>
        </div>
    );
}

function StatCard({
    title,
    value,
    change,
    trend,
    icon: Icon,
    trendColor = "default",
}: {
    title: string;
    value: string;
    change: string;
    trend: "up" | "down";
    icon: React.ElementType;
    trendColor?: "default" | "red";
}) {
    const isUp = trend === "up";
    const colorClass =
        trendColor === "red"
            ? "text-red-500"
            : isUp
                ? "text-green-500"
                : "text-red-500";

    return (
        <div className="rounded-xl bg-white p-6 shadow-sm dark:bg-gray-800">
            <div className="flex items-center justify-between">
                <div className="rounded-lg bg-primary/10 p-3">
                    <Icon className="h-6 w-6 text-primary" />
                </div>
                <div className={`flex items-center gap-1 text-sm ${colorClass}`}>
                    {isUp ? (
                        <ArrowUpRight className="h-4 w-4" />
                    ) : (
                        <ArrowDownRight className="h-4 w-4" />
                    )}
                    {change}
                </div>
            </div>
            <div className="mt-4">
                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                    {value}
                </p>
                <p className="text-sm text-gray-500 dark:text-gray-400">{title}</p>
            </div>
        </div>
    );
}

function PaymentItem({
    name,
    unit,
    amount,
    time,
}: {
    name: string;
    unit: string;
    amount: string;
    time: string;
}) {
    return (
        <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-green-100 text-green-600 dark:bg-green-900/20">
                    ₺
                </div>
                <div>
                    <p className="font-medium text-gray-900 dark:text-white">{name}</p>
                    <p className="text-sm text-gray-500">{unit}</p>
                </div>
            </div>
            <div className="text-right">
                <p className="font-medium text-gray-900 dark:text-white">{amount}</p>
                <p className="text-sm text-gray-500">{time}</p>
            </div>
        </div>
    );
}

function RequestItem({
    title,
    unit,
    status,
    time,
}: {
    title: string;
    unit: string;
    status: "open" | "in_progress" | "resolved";
    time: string;
}) {
    const statusConfig = {
        open: { label: "Açık", color: "bg-yellow-100 text-yellow-700" },
        in_progress: { label: "İşlemde", color: "bg-blue-100 text-blue-700" },
        resolved: { label: "Çözüldü", color: "bg-green-100 text-green-700" },
    };
    const config = statusConfig[status];

    return (
        <div className="flex items-center justify-between">
            <div>
                <p className="font-medium text-gray-900 dark:text-white">{title}</p>
                <p className="text-sm text-gray-500">{unit} • {time}</p>
            </div>
            <span className={`rounded-full px-3 py-1 text-xs font-medium ${config.color}`}>
                {config.label}
            </span>
        </div>
    );
}
