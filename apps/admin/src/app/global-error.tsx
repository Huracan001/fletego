"use client";

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const message =
    error.message ||
    "Error inesperado en el panel admin. Revisa la configuración.";

  return (
    <html lang="es">
      <body
        style={{
          margin: 0,
          minHeight: "100vh",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          background: "#F6F8FC",
          color: "#0B1220",
          fontFamily: "system-ui, sans-serif",
          padding: 24,
        }}
      >
        <div
          style={{
            maxWidth: 480,
            width: "100%",
            background: "white",
            border: "1px solid #E2E8F0",
            borderRadius: 16,
            padding: 24,
          }}
        >
          <p
            style={{
              margin: 0,
              fontSize: 12,
              fontWeight: 700,
              letterSpacing: "0.14em",
              color: "#1769FF",
            }}
          >
            FLETEGO
          </p>
          <h1 style={{ margin: "8px 0 0", fontSize: 22 }}>
            No se pudo cargar Admin
          </h1>
          <p style={{ color: "#5B6B7C", fontSize: 14, lineHeight: 1.5 }}>
            {message}
          </p>
          <div style={{ display: "flex", gap: 8, marginTop: 16 }}>
            <button
              type="button"
              onClick={reset}
              style={{
                background: "#1769FF",
                color: "white",
                border: 0,
                borderRadius: 10,
                padding: "10px 14px",
                fontWeight: 600,
                cursor: "pointer",
              }}
            >
              Reintentar
            </button>
            <a
              href="/login"
              style={{
                border: "1px solid #E2E8F0",
                borderRadius: 10,
                padding: "10px 14px",
                textDecoration: "none",
                color: "#0B1220",
              }}
            >
              Ir al login
            </a>
          </div>
        </div>
      </body>
    </html>
  );
}
