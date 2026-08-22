import { useState } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import palette from "../../shared/palette.json";

const swatches = [
  { key: "lavender", label: "Lavender", use: "Destaque no modo escuro" },
  { key: "iris", label: "Iris", use: "Destaque no modo claro" },
  { key: "violet", label: "Violet", use: "Sombras e bordas" },
  { key: "indigo", label: "Indigo", use: "Topo do gradiente" },
  { key: "ink", label: "Ink", use: "Texto no modo claro" },
  { key: "slate", label: "Slate", use: "Texto secundário" },
  { key: "mist", label: "Mist", use: "Texto no modo escuro" },
  { key: "sky", label: "Sky", use: "Texto secundário no escuro" },
] as const;

const commands = {
  windows: [
    "git clone https://github.com/MarbleLabs1/bigsur-windows-glow.git",
    "cd bigsur-windows-glow\\windows",
    ".\\install.ps1 -Dark",
  ],
  linux: [
    "git clone https://github.com/MarbleLabs1/bigsur-windows-glow.git",
    "cd bigsur-windows-glow/linux",
    "./install.sh --dark",
  ],
};

function CommandBlock({ lines }: { lines: string[] }) {
  const [copied, setCopied] = useState(false);

  const copy = async () => {
    await navigator.clipboard.writeText(lines.join("\n"));
    setCopied(true);
    setTimeout(() => setCopied(false), 1800);
  };

  return (
    <div className="relative rounded-2xl bg-[#221F26]/85 p-5 pr-24 font-mono text-sm leading-relaxed text-[#E5DEFF] shadow-inner">
      {lines.map((line) => (
        <div key={line} className="whitespace-pre-wrap break-all">
          <span className="select-none text-[#9b87f5]">$ </span>
          {line}
        </div>
      ))}
      <Button
        size="sm"
        variant="secondary"
        onClick={copy}
        className="absolute right-3 top-3 bg-[#9b87f5]/25 text-[#E5DEFF] hover:bg-[#9b87f5]/40"
      >
        {copied ? "Copiado" : "Copiar"}
      </Button>
    </div>
  );
}

const Index = () => {
  const colors = palette.colors as Record<string, string>;

  return (
    <main className="min-h-screen bg-gradient-to-tr from-[#D6BCFA] via-[#9b87f5] to-[#6E59A5] px-6 py-16">
      <div className="mx-auto flex max-w-4xl flex-col gap-10">
        <header className="text-center">
          <h1 className="text-5xl font-bold tracking-tight text-[#221F26]">
            Big Sur Glow
          </h1>
          <p className="mx-auto mt-4 max-w-xl text-lg font-medium text-[#403E43]">
            Tema de área de trabalho inspirado no macOS Big Sur, para Windows
            10/11 e Linux. Reversível — o instalador guarda o estado anterior
            antes de mudar qualquer coisa.
          </p>
        </header>

        <Card className="rounded-3xl border border-[#9b87f5]/30 bg-white/25 shadow-lg shadow-[#7E69AB]/40 backdrop-blur-lg">
          <CardContent className="p-8">
            <h2 className="mb-5 text-xl font-semibold text-[#221F26]">
              Instalação
            </h2>
            <Tabs defaultValue="windows">
              <TabsList className="mb-4 bg-[#221F26]/10">
                <TabsTrigger value="windows">Windows</TabsTrigger>
                <TabsTrigger value="linux">Linux</TabsTrigger>
              </TabsList>
              <TabsContent value="windows">
                <CommandBlock lines={commands.windows} />
                <p className="mt-3 text-sm text-[#403E43]">
                  Sem <code>-Dark</code> aplica a variante clara. Para desfazer:{" "}
                  <code>.\uninstall.ps1</code>
                </p>
              </TabsContent>
              <TabsContent value="linux">
                <CommandBlock lines={commands.linux} />
                <p className="mt-3 text-sm text-[#403E43]">
                  GNOME, Cinnamon, MATE, XFCE e KDE. Para desfazer:{" "}
                  <code>./uninstall.sh</code>
                </p>
              </TabsContent>
            </Tabs>
          </CardContent>
        </Card>

        <Card className="rounded-3xl border border-[#9b87f5]/30 bg-white/25 shadow-lg shadow-[#7E69AB]/40 backdrop-blur-lg">
          <CardContent className="p-8">
            <h2 className="mb-1 text-xl font-semibold text-[#221F26]">
              A paleta
            </h2>
            <p className="mb-6 text-sm text-[#403E43]">
              Lida de <code>shared/palette.json</code> — a mesma fonte que os
              instaladores usam.
            </p>
            <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
              {swatches.map(({ key, label, use }) => (
                <div key={key} className="flex flex-col gap-2">
                  <div
                    className="h-20 rounded-2xl border border-white/40 shadow-md"
                    style={{ backgroundColor: colors[key] }}
                  />
                  <div>
                    <div className="text-sm font-semibold text-[#221F26]">
                      {label}
                    </div>
                    <div className="font-mono text-xs text-[#403E43]">
                      {colors[key]}
                    </div>
                    <div className="mt-0.5 text-xs text-[#403E43]/80">{use}</div>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        <footer className="pb-4 text-center text-sm text-[#403E43]">
          <a
            href="https://github.com/MarbleLabs1/bigsur-windows-glow"
            className="font-semibold underline underline-offset-4"
          >
            Repositório
          </a>
          <span className="mx-2">·</span>
          <a
            href="https://github.com/MarbleCeo/macos-theme-for-linux"
            className="font-semibold underline underline-offset-4"
          >
            macOS Theme for Linux
          </a>
          <div className="mt-3 text-xs text-[#403E43]/80">
            Não afiliado à Apple Inc. &quot;macOS&quot; e &quot;Big Sur&quot; são
            marcas da Apple Inc.
          </div>
        </footer>
      </div>
    </main>
  );
};

export default Index;
