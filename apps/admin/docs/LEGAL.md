# FLETEGO — Legal & public URLs

Plantillas MVP en español (Bolivia). Revisar con abogado antes de un lanzamiento amplio.

## Rutas (apps/admin)

| Documento | Ruta |
|-----------|------|
| Índice | `/legal` |
| Privacidad | `/privacy` |
| Términos | `/terms` |

Contacto usado en los textos: `soporte@fletego.app` (cámbialo si usas otro).

## Deploy en Vercel (panel + legales)

1. Importa el repo `Huracan001/fletego` en [Vercel](https://vercel.com).
2. **Root Directory:** `apps/admin`
3. Framework: Next.js (auto)
4. Env vars:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`
5. Deploy.

URLs típicas (ajusta al dominio que te asigne Vercel):

```
https://TU-PROYECTO.vercel.app/privacy
https://TU-PROYECTO.vercel.app/terms
```

Usa esas URLs en:
- Google Play Console → Política de privacidad
- App Store Connect → Privacy Policy URL
- Ficha de la app / sitio

Opcional: conecta un dominio propio (`legal.fletego.app` o `www.fletego.app`).

## Local

```bash
cd apps/admin
npm run dev
# http://localhost:3000/privacy
# http://localhost:3000/terms
```
