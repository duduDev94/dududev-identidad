
/* =========================================
   duduDev - Brand Identity
   Funciones e interacciones
========================================= */

// Año automático
document.getElementById("year").textContent =
    new Date().getFullYear();


// Menú móvil
const menuToggle = document.getElementById("menuToggle");
const navLinks = document.getElementById("navLinks");

menuToggle.addEventListener("click", () => {
    navLinks.classList.toggle("active");

    const abierto = navLinks.classList.contains("active");

    menuToggle.setAttribute(
        "aria-label",
        abierto ? "Cerrar menú" : "Abrir menú"
    );

    menuToggle.textContent = abierto ? "✕" : "☰";
});


// Cerrar menú al seleccionar una sección
document.querySelectorAll(".nav-links a").forEach(link => {
    link.addEventListener("click", () => {
        navLinks.classList.remove("active");
        menuToggle.textContent = "☰";
    });
});


// Copiar códigos HEX
const botonesColor = document.querySelectorAll(".copy-color");
const toast = document.getElementById("toast");

let toastTimer;

botonesColor.forEach(boton => {

    boton.addEventListener("click", async () => {

        const color = boton.dataset.color;

        try {
            await navigator.clipboard.writeText(color);

            toast.textContent = `${color} copiado correctamente`;
            toast.classList.add("show");

            clearTimeout(toastTimer);

            toastTimer = setTimeout(() => {
                toast.classList.remove("show");
            }, 2000);

        } catch (error) {
            toast.textContent = "No se pudo copiar el color";
            toast.classList.add("show");

            clearTimeout(toastTimer);

            toastTimer = setTimeout(() => {
                toast.classList.remove("show");
            }, 2000);
        }

    });

});


// Animación de aparición al desplazarse
const elementos = document.querySelectorAll(
    ".identity-card, .color-card, .font-card, .application-card"
);

if ("IntersectionObserver" in window) {

    const observador = new IntersectionObserver((entradas) => {

        entradas.forEach(entrada => {

            if (entrada.isIntersecting) {
                entrada.target.classList.add("visible");
                observador.unobserve(entrada.target);
            }

        });

    }, {
        threshold: 0.12
    });

    elementos.forEach(elemento => {
        elemento.classList.add("reveal");
        observador.observe(elemento);
    });

}
