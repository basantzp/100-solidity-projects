// 100 Solidity Projects Web Explorer Engine
document.addEventListener("DOMContentLoaded", () => {
  const projects = window.PROJECTS_DATA || [];
  const grid = document.getElementById("projectsGrid");
  const emptyState = document.getElementById("emptyState");
  const searchInput = document.getElementById("searchInput");
  const filteredCountEl = document.getElementById("filteredCount");
  const pillarFiltersContainer = document.getElementById("pillarFilters");

  // Modal elements
  const modal = document.getElementById("codeModal");
  const modalProjectId = document.getElementById("modalProjectId");
  const modalProjectName = document.getElementById("modalProjectName");
  const modalProjectPillar = document.getElementById("modalProjectPillar");
  const modalGasBadge = document.getElementById("modalGasBadge");
  const modalCode = document.getElementById("modalCode");
  const modalTestCmd = document.getElementById("modalTestCmd");
  const modalGitHubLink = document.getElementById("modalGitHubLink");
  const tabSrcBtn = document.getElementById("tabSrcBtn");
  const tabTestBtn = document.getElementById("tabTestBtn");
  const copyModalCodeBtn = document.getElementById("copyModalCodeBtn");
  const copyBtnText = document.getElementById("copyBtnText");
  const copyTestCmdBtn = document.getElementById("copyTestCmdBtn");
  const closeModalBtn = document.getElementById("closeModalBtn");

  let currentPillar = "all";
  let activeProject = null;
  let activeTab = "src"; // 'src' | 'test'

  const pillarsList = [
    { num: 1, name: "Pillar 01: Tokens" },
    { num: 2, name: "Pillar 02: Custody" },
    { num: 3, name: "Pillar 03: AMMs" },
    { num: 4, name: "Pillar 04: Lending & Yield" },
    { num: 5, name: "Pillar 05: Cryptography" },
    { num: 6, name: "Pillar 06: EVM & Cancun" },
    { num: 7, name: "Pillar 07: Proxies" },
    { num: 8, name: "Pillar 08: DAOs" },
    { num: 9, name: "Pillar 09: Account Abstraction" },
    { num: 10, name: "Pillar 10: Cross-Chain & MEV" }
  ];

  // Render pillar filter buttons
  pillarsList.forEach(p => {
    const btn = document.createElement("button");
    btn.className = "filter-btn px-3 py-1.5 rounded-lg text-xs font-medium bg-gray-800 text-gray-300 hover:bg-gray-700 transition whitespace-nowrap";
    btn.dataset.pillar = p.num;
    btn.textContent = `${p.name} (10)`;
    pillarFiltersContainer.appendChild(btn);
  });

  // Filter button click handler
  pillarFiltersContainer.addEventListener("click", (e) => {
    const btn = e.target.closest(".filter-btn");
    if (!btn) return;

    document.querySelectorAll(".filter-btn").forEach(b => {
      b.className = "filter-btn px-3 py-1.5 rounded-lg text-xs font-medium bg-gray-800 text-gray-300 hover:bg-gray-700 transition whitespace-nowrap";
    });
    btn.className = "filter-btn active px-3 py-1.5 rounded-lg text-xs font-medium bg-emerald-500 text-black transition whitespace-nowrap font-bold";

    currentPillar = btn.dataset.pillar;
    render();
  });

  // Search input handler
  searchInput.addEventListener("input", () => {
    render();
  });

  function getFilteredProjects() {
    const query = searchInput.value.toLowerCase().trim();
    return projects.filter(p => {
      const matchesPillar = currentPillar === "all" || p.pillarNum === parseInt(currentPillar);
      if (!matchesPillar) return false;

      if (!query) return true;

      return (
        p.name.toLowerCase().includes(query) ||
        p.fileName.toLowerCase().includes(query) ||
        p.category.toLowerCase().includes(query) ||
        p.innovation.toLowerCase().includes(query) ||
        p.gasProfile.toLowerCase().includes(query) ||
        `#${p.id}`.includes(query)
      );
    });
  }

  function render() {
    const filtered = getFilteredProjects();
    filteredCountEl.textContent = filtered.length;
    grid.innerHTML = "";

    if (filtered.length === 0) {
      emptyState.classList.remove("hidden");
    } else {
      emptyState.classList.add("hidden");
    }

    filtered.forEach(p => {
      const card = document.createElement("div");
      card.className = "bg-[#111827]/70 hover:bg-[#131d31] border border-gray-800 hover:border-emerald-500/40 rounded-2xl p-5 flex flex-col justify-between transition-all duration-200 hover:shadow-xl hover:shadow-emerald-500/5 group";

      card.innerHTML = `
        <div>
          <div class="flex items-center justify-between mb-3">
            <span class="text-xs font-mono font-bold px-2 py-0.5 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
              #${String(p.id).padStart(2, '0')}
            </span>
            <span class="text-[11px] font-medium text-gray-400 bg-gray-800/80 px-2.5 py-0.5 rounded-full border border-gray-700/50">
              ${p.category}
            </span>
          </div>

          <h3 class="text-base font-bold text-white font-mono group-hover:text-emerald-300 transition flex items-center gap-1.5">
            ${p.fileName}
          </h3>

          <p class="text-xs text-gray-400 mt-2 line-clamp-2 leading-relaxed">
            ${p.innovation}
          </p>
        </div>

        <div class="mt-4 pt-3 border-t border-gray-800/80 flex items-center justify-between text-xs font-mono">
          <span class="text-gray-500 text-[11px]">${p.gasProfile}</span>
          <button class="inspect-btn text-xs font-semibold px-2.5 py-1 rounded-lg bg-gray-800 hover:bg-emerald-500 hover:text-black text-emerald-400 border border-gray-700 hover:border-emerald-500 transition flex items-center gap-1" data-id="${p.id}">
            <span>Inspect</span>
            <i data-lucide="chevron-right" class="w-3.5 h-3.5"></i>
          </button>
        </div>
      `;

      grid.appendChild(card);
    });

    if (window.lucide) {
      window.lucide.createIcons();
    }
  }

  // Open inspection modal
  grid.addEventListener("click", (e) => {
    const btn = e.target.closest(".inspect-btn");
    if (!btn) return;

    const pId = parseInt(btn.dataset.id);
    const p = projects.find(item => item.id === pId);
    if (!p) return;

    activeProject = p;
    activeTab = "src";

    modalProjectId.textContent = `#${String(p.id).padStart(2, '0')}`;
    modalProjectName.textContent = p.fileName;
    modalProjectPillar.textContent = `${p.pillar} • ${p.category}`;
    modalGasBadge.textContent = p.gasProfile;
    modalTestCmd.textContent = p.testCommand;
    modalGitHubLink.href = `https://github.com/basantzp/100-solidity-projects/blob/master/${p.srcPath}`;

    updateModalCode();
    modal.classList.remove("hidden");
  });

  function updateModalCode() {
    if (!activeProject) return;

    if (activeTab === "src") {
      tabSrcBtn.className = "pb-2 text-xs font-mono font-semibold text-emerald-400 border-b-2 border-emerald-500 transition";
      tabTestBtn.className = "pb-2 text-xs font-mono font-semibold text-gray-400 hover:text-gray-200 border-b-2 border-transparent transition";
      modalCode.textContent = activeProject.srcCode || "// Source code not found";
    } else {
      tabTestBtn.className = "pb-2 text-xs font-mono font-semibold text-emerald-400 border-b-2 border-emerald-500 transition";
      tabSrcBtn.className = "pb-2 text-xs font-mono font-semibold text-gray-400 hover:text-gray-200 border-b-2 border-transparent transition";
      modalCode.textContent = activeProject.testCode || "// Test code not found";
    }

    if (window.Prism) {
      Prism.highlightElement(modalCode);
    }
  }

  tabSrcBtn.addEventListener("click", () => {
    activeTab = "src";
    updateModalCode();
  });

  tabTestBtn.addEventListener("click", () => {
    activeTab = "test";
    updateModalCode();
  });

  closeModalBtn.addEventListener("click", () => {
    modal.classList.add("hidden");
  });

  modal.addEventListener("click", (e) => {
    if (e.target === modal) {
      modal.classList.add("hidden");
    }
  });

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && !modal.classList.contains("hidden")) {
      modal.classList.add("hidden");
    }
  });

  // Copy code button
  copyModalCodeBtn.addEventListener("click", () => {
    const textToCopy = modalCode.textContent;
    navigator.clipboard.writeText(textToCopy).then(() => {
      copyBtnText.textContent = "Copied!";
      setTimeout(() => {
        copyBtnText.textContent = "Copy Code";
      }, 2000);
    });
  });

  // Copy test command
  copyTestCmdBtn.addEventListener("click", () => {
    const cmd = modalTestCmd.textContent;
    navigator.clipboard.writeText(cmd).then(() => {
      copyTestCmdBtn.textContent = "Copied!";
      setTimeout(() => {
        copyTestCmdBtn.textContent = "Copy Command";
      }, 2000);
    });
  });

  // Initial render
  render();
});
