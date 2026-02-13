import Sidebar from './Sidebar';
import Header from './Header';
import { Breadcrumbs } from '../ui/breadcrumbs';

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-white">
      <Sidebar />
      <div className="md:ml-64 flex flex-col min-h-screen transition-all duration-300">
        <Header />
        <main className="flex-1 p-6 bg-white/50">
          <Breadcrumbs />
          {children}
        </main>
      </div>
    </div>
  );
}
