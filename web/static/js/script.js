//VAR GLOBALI

TEMPO_CHECK_LIC = 3600000; // 1 ORA --> 3600 Secondi
TEMPO_POOL_ORDINI = 5000; // 5 Secondi
TEMPO_REFRESH_PAGINA = 1000000000; // 60 Secondi

// ORARIO
const clockEl = document.getElementById("clock");
function updateClock() {
  const now = new Date();
  const hours = String(now.getHours()).padStart(2, "0");
  const minutes = String(now.getMinutes()).padStart(2, "0");
  const seconds = String(now.getSeconds()).padStart(2, "0");
  clockEl.textContent = `${hours}:${minutes}:${seconds}`;
}

// Variabile globale per moduli attivi
let activeModules = [];
/**
 * Mostra il modal per modulo non attivo
 * @param {string} modulo
 */
function openInactiveModal(modulo) {
  const modal = document.getElementById("inactiveModuleModal");
  const message = `⚠️ Il modulo "${modulo}" non è attivo! ⚠️<br>` +
                  `Devi contattare l'assistenza RistoSuite<br>Richiedi Supporto!`;
  document.getElementById("inactiveMessage").innerHTML = message;
  modal.style.display = "flex";

  document.getElementById("closeInactiveBtn").onclick = () => {
    modal.style.display = "none";
  };
}

/**
 * Applica restrizioni ai link basandosi sui moduli attivi
 */
function applyModuleRestrictions() {
  document.querySelectorAll(".modulo-link").forEach((link) => {
    const modulo = link.dataset.modulo?.toUpperCase() || "";

    // Rimuove listener precedenti per evitare duplicazioni
    link.replaceWith(link.cloneNode(true));
  });

  document.querySelectorAll(".modulo-link").forEach((link) => {
    const modulo = link.dataset.modulo?.toUpperCase() || "";

    if (!activeModules.includes(modulo)) {
      link.classList.add("disabled-link");
      link.addEventListener("click", (e) => {
        e.preventDefault();
        openInactiveModal(modulo);
      });
    } else {
      link.classList.remove("disabled-link");
    }
  });
}

/**
 * Invia i moduli attivi al server Flask
 */
async function syncModulesWithServer() {
  try {
    await fetch("/set_active_modules", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ activeModules })
    });
    console.log("✅ Moduli sincronizzati con il server");
  } catch (err) {
    console.error("❌ Errore sincronizzazione moduli con il server:", err);
  }
}

/**
 * Recupera moduli dalla cache o dal server se necessario
 */
async function checkLicense() {
  const lastCheck = parseInt(sessionStorage.getItem("last_check") || "0", 10);
  const now = Date.now();

  if (now - lastCheck > TEMPO_CHECK_LIC) {
    console.log("⏱️ Più di un'ora, eseguo nuovo check licenza...");
    sessionStorage.setItem("last_check", now);

    try {
      const response = await fetch("/check_license");
      const data = await response.json();

      activeModules = data.valid
        ? data.license.modules.map((m) => m.toUpperCase())
        : [];

        sessionStorage.setItem("activeModules", JSON.stringify(activeModules));
      } catch (err) {
        console.error("Errore fetch licenza:", err);
        activeModules = [];
        sessionStorage.setItem("activeModules", JSON.stringify(activeModules));
      }
    } else {
      console.log("✅ Check licenza recente, uso cache");
      const cachedModules = sessionStorage.getItem("activeModules");
      activeModules = cachedModules ? JSON.parse(cachedModules) : [];
    }
    
  await syncModulesWithServer(); // invio moduli al server
  applyModuleRestrictions();
}

// Avvia controllo subito al caricamento
checkLicense();
// Mostra toast già presenti
function showToasts(containerId) {
  const toastElList = [].slice.call(
    document.querySelectorAll(`#${containerId} .toast`)
  );
  toastElList
    .map((el) => new bootstrap.Toast(el, { delay: 4000, animation: true }))
    .forEach((toast) => toast.show());
}

window.addEventListener("DOMContentLoaded", () => {
  // Mostra toast di benvenuto dopo un piccolo delay
  setTimeout(() => showToasts("Benvenuto"), 100);
  updateClock();
  setInterval(updateClock, 1000);
  // Avvia polling per nuovi ordini
  //setInterval(checkLicense, 64800000);
  setInterval(checkLicense, TEMPO_CHECK_LIC);
  //setInterval(pollNuoviOrdini, TEMPO_POOL_ORDINI);
});

// --- Polling per nuovi ordini ---
async function pollNuoviOrdini() {
  try {
    const response = await fetch("/api/nuovi_ordini"); // nessun last_id da passare
    if (response.ok) {
      const data = await response.json();
      if (data.nuovi_ordini && data.nuovi_ordini.length > 0) {
        data.nuovi_ordini.forEach((ordine) => {
          const ordiniContainer = document.getElementById("Ordini");
          const toast = document.createElement("div");
          toast.className =
            "toast align-items-center text-bg-success border-0 ordini";
          toast.setAttribute("role", "alert");
          toast.setAttribute("aria-live", "assertive");
          toast.setAttribute("aria-atomic", "true");
          toast.innerHTML = `
                        <div class="d-flex">
                            <div class="toast-body">
                                Nuovo ordine da ${ordine.operatore}: Totale €${ordine.totale}
                            </div>
                            <button type="button" class="btn-close btn-close-white me-2 m-auto"
                                data-bs-dismiss="toast" aria-label="Close"></button>
                        </div>
                    `;
          ordiniContainer.appendChild(toast);
          new bootstrap.Toast(toast, { delay: 4000, animation: true }).show();
        });
      }
    }
  } catch (err) {
    console.error("Errore nel polling nuovi ordini:", err);
  }
}

const btn = document.getElementById("supportBtn");
const popup = document.getElementById("supportPopup");
const content = popup.querySelector(".popup-content");
const close = document.getElementById("closeSupport");

// Apri popup
btn.addEventListener("click", () => {
  popup.classList.add("show");
  content.classList.remove("fade-out");
  content.classList.add("fade-in");
});

// Chiudi popup (bottone)
close.addEventListener("click", () => {
  content.classList.remove("fade-in");
  content.classList.add("fade-out");

  content.addEventListener(
    "animationend",
    () => {
      if (content.classList.contains("fade-out")) {
        popup.classList.remove("show");
      }
    },
    { once: true }
  );
});

// Chiudi cliccando fuori dal box
popup.addEventListener("click", (e) => {
  if (e.target === popup) close.click();
});

// refresh ogni 60 secondi (60000 ms)
setInterval(() => {
  location.reload();
}, TEMPO_REFRESH_PAGINA);
document.addEventListener("DOMContentLoaded", () => {
  // Percorso attuale
  const currentPath = window.location.pathname.replace(/\/$/, "") || "/";

  // Seleziona tutti i link principali della navbar (ignora dropdown e session user)
  const navLinks = document.querySelectorAll("nav.navbar a.nav-link.check");

  navLinks.forEach((link) => {
    const linkPath = new URL(link.href).pathname.replace(/\/$/, "") || "/";
    if (linkPath === currentPath) {
      link.classList.add("active");
      link.setAttribute("aria-current", "page"); // accessibilità
    }
  });
});

//MODAL ELIMINA

// Gestione modal e POST sicuro
document.querySelectorAll(".btn-elimina").forEach((btn) => {
  btn.addEventListener("click", function (e) {
    e.preventDefault();
    const action = this.dataset.action;
    const modal = document.getElementById("confirmModal");
    modal.classList.add("show");

    document.getElementById("confirmBtn").onclick = function () {
      const form = document.getElementById("deleteForm");
      form.action = action;
      form.submit();
    };

    document.getElementById("cancelBtn").onclick = function () {
      modal.classList.remove("show");
    };
  });
});
