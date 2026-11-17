/**
 * duduDev - Google Analytics 4
 * Seguimiento de interacciones del sitio.
 *
 * Requiere que gtag.js esté instalado previamente en index.html.
 */

(function () {
    "use strict";

    // Evitar inicializacion duplicada.
    if (window.duduAnalyticsEventsLoaded) return;
    window.duduAnalyticsEventsLoaded = true;

    /**
     * Envia un evento a Google Analytics.
     */
    function trackEvent(eventName, parameters) {
        if (typeof window.gtag !== "function") {
            console.warn("[duduDev Analytics] gtag no esta disponible:", eventName);
            return;
        }

        window.gtag("event", eventName, parameters || {});
    }

    /**
     * Obtiene texto util de un elemento.
     */
    function getElementLabel(element) {
        return (
            element.getAttribute("data-analytics-label") ||
            element.getAttribute("aria-label") ||
            element.innerText ||
            element.textContent ||
            element.getAttribute("title") ||
            element.getAttribute("href") ||
            "sin_etiqueta"
        ).trim().replace(/\s+/g, " ").slice(0, 100);
    }

    /**
     * 1. EVENTOS PERSONALIZADOS
     *
     * Ejemplo:
     * <a data-analytics-event="view_services"
     *    data-analytics-label="Ver servicios">
     *    Ver servicios
     * </a>
     */
    document.addEventListener("click", function (event) {
        const element = event.target.closest("[data-analytics-event]");

        if (!element) return;

        const eventName = element.getAttribute("data-analytics-event");

        // Solo permitir nombres de eventos GA4 sencillos.
        if (!/^[a-z][a-z0-9_]{0,39}$/.test(eventName || "")) {
            console.warn("[duduDev Analytics] Nombre de evento no valido:", eventName);
            return;
        }

        trackEvent(eventName, {
            event_category: element.getAttribute("data-analytics-category") || "interaction",
            event_label: getElementLabel(element),
            element_text: getElementLabel(element),
            page_location: window.location.href
        });
    });

    /**
     * 2. APERTURA DE PROYECTOS
     *
     * Ejemplo:
     * <a href="/proyecto.html"
     *    data-project="Dashboard de ventas">
     *    Ver proyecto
     * </a>
     */
    document.addEventListener("click", function (event) {
        const element = event.target.closest("[data-project]");

        if (!element) return;

        trackEvent("view_project", {
            project_name: element.getAttribute("data-project"),
            project_location: element.getAttribute("href") || "",
            page_location: window.location.href
        });
    });

    /**
     * 3. CLICS DE CONTACTO
     * Detecta correo, telefono y WhatsApp.
     */
    document.addEventListener("click", function (event) {
        const link = event.target.closest("a[href]");

        if (!link) return;

        const href = link.getAttribute("href") || "";
        let method = "";

        if (href.startsWith("mailto:")) {
            method = "email";
        } else if (href.startsWith("tel:")) {
            method = "phone";
        } else if (
            href.includes("wa.me/") ||
            href.includes("whatsapp.com/")
        ) {
            method = "whatsapp";
        }

        if (!method) return;

        trackEvent("contact_click", {
            contact_method: method,
            link_url: href,
            link_text: getElementLabel(link)
        });
    });

    /**
     * 4. FORMULARIOS
     *
     * Detecta el envio de formularios marcados.
     * El evento generate_lead solo se registra cuando
     * el formulario confirma que el envio fue exitoso.
     */
    document.addEventListener("submit", function (event) {
        const form = event.target;

        if (!form.matches("[data-analytics-form]")) return;

        trackEvent("form_submit", {
            form_name: form.getAttribute("data-analytics-form"),
            form_destination: form.getAttribute("action") || "",
            page_location: window.location.href
        });
    });

    /**
     * Evento de exito de formulario.
     *
     * Desde tu codigo de formulario, despues de confirmar
     * el exito del servidor, ejecuta:
     *
     * form.dispatchEvent(new CustomEvent("dudu:form-success"));
     *
     * El formulario debe tener data-analytics-form.
     */
    document.addEventListener("dudu:form-success", function (event) {
        const form = event.target;

        if (!form || !form.matches || !form.matches("[data-analytics-form]")) {
            return;
        }

        trackEvent("generate_lead", {
            form_name: form.getAttribute("data-analytics-form"),
            lead_source: "website",
            page_location: window.location.href
        });
    });

    /**
     * 5. ENLACES EXTERNOS
     */
    document.addEventListener("click", function (event) {
        const link = event.target.closest("a[href]");

        if (!link) return;

        const href = link.href;

        if (!href || !/^https?:\/\//i.test(href)) return;

        try {
            const destination = new URL(href);
            const current = window.location.hostname;

            if (destination.hostname === current) return;

            // Los contactos tienen su propio evento.
            if (
                href.startsWith("mailto:") ||
                href.startsWith("tel:") ||
                href.includes("wa.me/") ||
                href.includes("whatsapp.com/")
            ) return;

            trackEvent("outbound_click", {
                link_url: href,
                link_domain: destination.hostname,
                link_text: getElementLabel(link)
            });
        } catch (error) {
            console.warn("[duduDev Analytics] No se pudo analizar el enlace.", error);
        }
    });

    /**
     * 6. VISITA A UNA PAGINA DE PROYECTO
     *
     * Para activarlo, agrega al body:
     * <body data-project-page="Dashboard de ventas">
     */
    const projectPage = document.body.getAttribute("data-project-page");

    if (projectPage) {
        trackEvent("project_page_view", {
            project_name: projectPage,
            page_location: window.location.href
        });
    }

    console.info("[duduDev Analytics] Eventos personalizados inicializados.");

})();