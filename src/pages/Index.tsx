
// We will update the Index.tsx page to have a Big Sur-inspired theme using the provided color palette
// and apply a nice big sur themed card with gradient and font style.

import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card";

const Index = () => {
  return (
    <main className="min-h-screen bg-gradient-to-tr from-[#D6BCFA] via-[#9b87f5] to-[#6E59A5] flex items-center justify-center p-10">
      <Card className="max-w-xl bg-gradient-to-br from-[#D6BCFA]/60 to-[#9b87f5]/80 backdrop-blur-lg border border-[#9b87f5]/30 shadow-lg shadow-[#7E69AB]/50 rounded-3xl">
        <CardHeader className="text-center p-8">
          <CardTitle className="text-4xl font-playfair font-bold text-[#221F26] dark:text-[#E5DEFF]">
            Welcome to Big Sur Themed W11Pro
          </CardTitle>
          <CardDescription className="text-lg text-[#403E43] dark:text-[#D3E4FD] mt-4 max-w-lg mx-auto font-semibold">
            This is a beautiful Big Sur inspired theme with soft pastel purples and elegant gradients.
          </CardDescription>
        </CardHeader>
        <CardContent className="px-12 pb-10 text-[#403E43] dark:text-[#D3E4FD] font-semibold leading-relaxed">
          Start building your amazing project here with the power of React, TailwindCSS, and shadcn UI components!
        </CardContent>
      </Card>
    </main>
  )
}

export default Index;

