import type { Metadata } from "next";
import { LegalSection, LegalShell } from "@/components/legal-shell";

export const metadata: Metadata = {
  title: "Política de Privacidad · FLETEGO",
  description:
    "Cómo FLETEGO by Pick&Truck trata datos personales de usuarios en Bolivia.",
};

export default function PrivacyPage() {
  return (
    <LegalShell title="Política de Privacidad" updated="17 de agosto de 2026">
      <LegalSection title="1. Quiénes somos">
        <p>
          <strong>FLETEGO</strong> es un marketplace digital de transporte
          pesado operado bajo la marca <strong>Pick&Truck</strong> (“nosotros”,
          “el Servicio”). Esta política describe cómo recopilamos, usamos y
          protegemos datos personales cuando usas la app móvil FLETEGO o el
          panel administrativo asociado.
        </p>
        <p>
          Contacto de privacidad:{" "}
          <a
            className="text-[var(--fg-primary)] underline"
            href="mailto:soporte@fletego.app"
          >
            soporte@fletego.app
          </a>
          .
        </p>
      </LegalSection>

      <LegalSection title="2. Datos que tratamos">
        <p>Según tu rol (cliente, conductor, empresa u operador), podemos tratar:</p>
        <ul>
          <li>
            <strong>Cuenta:</strong> correo electrónico, nombre, teléfono, CI u
            otros identificadores que proporciones.
          </li>
          <li>
            <strong>Perfil operativo:</strong> tipo de usuario, empresa, rol
            dentro de la empresa, licencia de conducir, datos de vehículos
            (placa, capacidad, documentos).
          </li>
          <li>
            <strong>Solicitudes y viajes:</strong> origen/destino, carga,
            ofertas, estado del viaje, historial de estados, evidencias de
            recogida/entrega (POD), calificaciones y mensajes del chat del
            viaje.
          </li>
          <li>
            <strong>Ubicación:</strong> si usas funciones de seguimiento, puntos
            de ubicación asociados al viaje (cuando estén activos).
          </li>
          <li>
            <strong>Técnicos:</strong> identificadores de sesión, logs de
            seguridad y metadatos necesarios para operar el Servicio
            (proveedor: Supabase / infraestructura cloud).
          </li>
        </ul>
      </LegalSection>

      <LegalSection title="3. Finalidades">
        <ul>
          <li>Crear y autenticar tu cuenta.</li>
          <li>Conectar clientes con transportistas y gestionar viajes.</li>
          <li>Verificar identidad/documentos cuando corresponda.</li>
          <li>Enviar notificaciones in-app relacionadas con tu actividad.</li>
          <li>Prevenir fraude, abuso y mejorar la seguridad del Servicio.</li>
          <li>Cumplir obligaciones legales aplicables en Bolivia.</li>
        </ul>
      </LegalSection>

      <LegalSection title="4. Base / consentimiento">
        <p>
          Usamos tus datos porque son necesarios para prestar el Servicio que
          solicitas (contrato/relación de uso), porque nos das consentimiento
          al registrarte y aceptar esta política, o porque tenemos un interés
          legítimo en proteger la plataforma y a otros usuarios.
        </p>
      </LegalSection>

      <LegalSection title="5. Encargados y almacenamiento">
        <p>
          Hospedamos datos principalmente a través de{" "}
          <strong>Supabase</strong> (autenticación, base de datos, almacenamiento
          y funciones relacionadas) y servicios de despliegue web (p. ej.
          Vercel para el panel). Pueden procesarse en servidores fuera de
          Bolivia. Aplicamos controles de acceso (incluye roles de plataforma y
          políticas de seguridad) para limitar quién puede ver tu información.
        </p>
      </LegalSection>

      <LegalSection title="6. Conservación">
        <p>
          Conservamos los datos mientras tu cuenta esté activa y el tiempo
          adicional necesario para disputas, requisitos legales o seguridad.
          Algunos registros pueden soft-eliminarse (ocultarse) sin borrado
          inmediato completo.
        </p>
      </LegalSection>

      <LegalSection title="7. Compartición">
        <p>No vendemos tus datos personales. Podemos compartir información:</p>
        <ul>
          <li>
            Con la contraparte de un viaje (p. ej. datos necesarios para
            cumplir el flete).
          </li>
          <li>
            Con miembros autorizados de tu empresa, según el rol asignado.
          </li>
          <li>
            Con proveedores técnicos que nos ayudan a operar el Servicio bajo
            obligaciones de confidencialidad.
          </li>
          <li>Cuando la ley o una autoridad competente lo requiera.</li>
        </ul>
      </LegalSection>

      <LegalSection title="8. Tus derechos">
        <p>
          Puedes solicitar acceso, actualización o eliminación de tu cuenta
          contactando{" "}
          <a
            className="text-[var(--fg-primary)] underline"
            href="mailto:soporte@fletego.app"
          >
            soporte@fletego.app
          </a>
          . Responderemos en un plazo razonable conforme a la normativa
          aplicable y a limitaciones técnicas/legales.
        </p>
      </LegalSection>

      <LegalSection title="9. Seguridad">
        <p>
          Usamos autenticación, control de acceso y prácticas de endurecimiento
          (p. ej. claves de servicio solo en servidor). Ningún sistema es 100%
          seguro; te pedimos proteger tu contraseña y dispositivo.
        </p>
      </LegalSection>

      <LegalSection title="10. Menores">
        <p>
          El Servicio está dirigido a mayores de edad con capacidad para
          contratar transporte comercial. No recopilamos a sabiendas datos de
          menores.
        </p>
      </LegalSection>

      <LegalSection title="11. Cambios">
        <p>
          Podemos actualizar esta política. Publicaremos la fecha de
          actualización en esta página. El uso continuado del Servicio después
          de cambios relevantes implica que tomaste conocimiento de la nueva
          versión.
        </p>
      </LegalSection>
    </LegalShell>
  );
}
