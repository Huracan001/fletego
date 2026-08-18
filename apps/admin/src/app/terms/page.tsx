import type { Metadata } from "next";
import Link from "next/link";
import { LegalSection, LegalShell } from "@/components/legal-shell";

export const metadata: Metadata = {
  title: "Términos de Uso · FLETEGO",
  description:
    "Condiciones de uso del marketplace FLETEGO by Pick&Truck en Bolivia.",
};

export default function TermsPage() {
  return (
    <LegalShell title="Términos de Uso" updated="17 de agosto de 2026">
      <LegalSection title="1. Aceptación">
        <p>
          Al crear una cuenta o usar <strong>FLETEGO</strong> (“el Servicio”),
          aceptas estos Términos de Uso y la{" "}
          <Link href="/privacy" className="text-[var(--fg-primary)] underline">
            Política de Privacidad
          </Link>
          . Si no estás de acuerdo, no uses el Servicio.
        </p>
      </LegalSection>

      <LegalSection title="2. Qué es FLETEGO">
        <p>
          FLETEGO by Pick&Truck es una plataforma tecnológica que facilita el
          contacto entre quienes necesitan transporte de carga y quienes
          ofrecen capacidad de transporte (conductores, flotas y empresas).{" "}
          <strong>
            FLETEGO no es el transportista ni el dueño de la carga
          </strong>
          , salvo que se indique expresamente lo contrario en un contrato
          separado.
        </p>
      </LegalSection>

      <LegalSection title="3. Cuentas y roles">
        <ul>
          <li>
            Debes proporcionar información veraz y mantenerla actualizada.
          </li>
          <li>
            Eres responsable de la confidencialidad de tus credenciales y de la
            actividad realizada con tu cuenta.
          </li>
          <li>
            Puedes operar como cliente, conductor y/o miembro de empresa según
            el onboarding y permisos asignados.
          </li>
          <li>
            Nos reservamos el derecho de suspender o terminar cuentas por
            fraude, abuso, documentación falsa o incumplimiento de estos
            términos.
          </li>
        </ul>
      </LegalSection>

      <LegalSection title="4. Solicitudes, ofertas y viajes">
        <ul>
          <li>
            Las solicitudes de carga, ofertas, aceptación y estados del viaje
            son actos entre las partes del flete.
          </li>
          <li>
            Los precios, plazos y condiciones comerciales los definen las
            partes a través del flujo de la app (salvo reglas futuras de la
            plataforma que se comuniquen claramente).
          </li>
          <li>
            Debes cumplir la normativa boliviana aplicable al transporte,
            carga, aduanas, seguridad vial y documentación del vehículo /
            conductor.
          </li>
          <li>
            La prueba de entrega (POD), chat, tracking y calificaciones son
            herramientas de soporte; no garantizan por sí solas el resultado
            comercial del flete.
          </li>
        </ul>
      </LegalSection>

      <LegalSection title="5. Verificación">
        <p>
          Podemos solicitar y revisar documentos (identidad, licencia,
          vehículo, empresa). La verificación puede ser parcial en etapas MVP.
          Una cuenta “aprobada” no constituye certificación legal definitiva
          ante autoridades.
        </p>
      </LegalSection>

      <LegalSection title="6. Pagos">
        <p>
          En la versión actual del MVP, el Servicio puede no procesar pagos
          dentro de la app. Cualquier cobro entre partes es responsabilidad de
          esas partes, salvo que habilitemos un proveedor de pagos y lo
          indiquemos en una actualización de estos términos.
        </p>
      </LegalSection>

      <LegalSection title="7. Contenido y uso aceptable">
        <p>No está permitido:</p>
        <ul>
          <li>Usar el Servicio para actividades ilícitas.</li>
          <li>Suplantar identidades o falsificar documentos.</li>
          <li>Interferir con la seguridad o disponibilidad de la plataforma.</li>
          <li>
            Acosar a otros usuarios o publicar información confidencial de
            terceros sin autorización.
          </li>
        </ul>
      </LegalSection>

      <LegalSection title="8. Disponibilidad">
        <p>
          El Servicio se ofrece “tal cual” y “según disponibilidad”. Pueden
          existir interrupciones por mantenimiento, fallas de terceros (maps,
          cloud, redes) o fuerza mayor.
        </p>
      </LegalSection>

      <LegalSection title="9. Limitación de responsabilidad">
        <p>
          En la máxima medida permitida por la ley, Pick&Truck / FLETEGO no
          será responsable por daños indirectos, lucro cesante, pérdida de
          datos o disputas comerciales entre clientes y transportistas
          derivadas del uso del marketplace. Nuestra responsabilidad agregada,
          si existiera, se limitará en la medida legalmente posible a los
          montos efectivamente pagados a la plataforma (si los hubiera) en los
          3 meses previos al reclamo.
        </p>
      </LegalSection>

      <LegalSection title="10. Propiedad intelectual">
        <p>
          La marca FLETEGO, Pick&Truck, el software, diseño y contenidos de la
          plataforma son propiedad de sus titulares. No se concede licencia
          más allá del uso del Servicio conforme a estos términos.
        </p>
      </LegalSection>

      <LegalSection title="11. Ley aplicable">
        <p>
          Estos términos se rigen por las leyes de <strong>Bolivia</strong>.
          Cualquier controversia se intentará resolver de buena fe; en su
          defecto, serán competentes los tribunales de Santa Cruz de la Sierra,
          salvo norma imperativa en contrario.
        </p>
      </LegalSection>

      <LegalSection title="12. Contacto">
        <p>
          Consultas sobre estos términos:{" "}
          <a
            className="text-[var(--fg-primary)] underline"
            href="mailto:soporte@fletego.app"
          >
            soporte@fletego.app
          </a>
          .
        </p>
      </LegalSection>
    </LegalShell>
  );
}
