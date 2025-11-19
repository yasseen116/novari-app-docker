// Refined script.js for a more elegant, professional front-end experience

const API_URL = window.location.origin + "/api/products";
let fetchedProducts = [];
let backendFavorites = [];

// --- UTILS ---
function showLoading(containerId) {
  const container = document.getElementById(containerId);
  container.innerHTML = `
    <div class="w-100 text-center py-5">
      <div class="spinner-border text-primary" role="status"></div>
      <div class="mt-2">Loading products...</div>
    </div>`;
}

function showError(containerId, msg = "⚠️ Failed to load products. Please try again.") {
  const container = document.getElementById(containerId);
  container.innerHTML = `
    <div class="alert alert-danger text-center">${msg}</div>`;
}

function getFavorites() {
  return JSON.parse(localStorage.getItem("favorites") || "[]");
}
function saveFavorites(favs) {
  localStorage.setItem("favorites", JSON.stringify(favs));
}

function getCart() {
  return JSON.parse(localStorage.getItem("cart") || "[]");
}
function saveCart(cart) {
  localStorage.setItem("cart", JSON.stringify(cart));
}

function escapeHtml(value = "") {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function normalizeSizes(product) {
  if (!product) return [];

  const rawSizes = Array.isArray(product.sizes)
    ? product.sizes
    : (typeof product.sizes === "string" ? product.sizes.split(",") : []);

  let sizes = rawSizes
    .map(size => {
      if (typeof size === "string") return size.trim();
      if (size && typeof size === "object") {
        return (size.size_label || size.label || size.value || "").trim();
      }
      return "";
    })
    .filter(Boolean);

  if (!sizes.length && Array.isArray(product.size_labels)) {
    sizes = product.size_labels.map(size => String(size).trim()).filter(Boolean);
  }

  if (!sizes.length && Array.isArray(product.availableSizes)) {
    sizes = product.availableSizes.map(size => String(size).trim()).filter(Boolean);
  }

  if (!sizes.length && typeof product.available_sizes === "string") {
    sizes = product.available_sizes.split(",").map(size => size.trim()).filter(Boolean);
  }

  return sizes;
}

function resolveProductImage(product) {
  const fallback = "/static/img/default.jpg";
  if (!product) return fallback;

  const candidates = [];
  if (Array.isArray(product.images) && product.images.length) {
    candidates.push(product.images[0]);
  }
  if (product.image) {
    candidates.push(product.image);
  }
  if (product.image_url) {
    candidates.push(product.image_url);
  }
  if (Array.isArray(product.photos) && product.photos.length) {
    const firstPhoto = product.photos[0];
    if (typeof firstPhoto === "string") {
      candidates.push(firstPhoto);
    } else if (firstPhoto && typeof firstPhoto === "object" && firstPhoto.image_url) {
      candidates.push(firstPhoto.image_url);
    }
  }

  const src = candidates.find(Boolean);
  if (!src) return fallback;
  if (src.startsWith("http")) return src;
  if (src.startsWith("/static/")) return src;
  return `/static/uploads/${src.replace(/^\/+/, "")}`;
}

// --- RENDER ---
async function renderProducts(products, containerId) {
  await fetchBackendFavorites();
  const container = document.getElementById(containerId);
  container.innerHTML = products.map(p => {
    let main = p.images && p.images[0] ? p.images[0] : '/static/img/default.jpg';
    if (main && !main.startsWith('/static/')) {
      main = '/static/uploads/' + main;
    }
    const isFavorite = isFav(p.id) ? 'active' : '';

    return `
      <div class="col-lg-3 col-md-4 col-sm-6 mb-4">
        <div class="product-card shadow-sm" onclick="window.location.href='/product/${p.id}.html'" style="cursor:pointer;">
          <div class="product-image-container position-relative overflow-hidden">
            <img src="${main}" alt="${p.title}" class="w-100 product-image" onerror="this.onerror=null;this.src='/static/img/default.jpg';">
            <button class="quick-view-btn" onclick="event.stopPropagation(); window.location.href='/product/${p.id}.html'">
              Quick View
            </button>
            <button class="favorite-btn ${isFavorite}" data-product-id="${p.id}" onclick="addToWishlist(event, ${p.id})">
              <i class="fas fa-heart"></i>
            </button>
          </div>
          <div class="product-info text-center mt-2">
            <h5 class="product-title mb-1 text-dark text-truncate fw-semibold">${p.title}</h5>
            <p class="product-price text-muted mb-0">EGP ${p.price.toFixed(2)}</p>
          </div>
        </div>
      </div>
    `;
  }).join('');
  updateAllFavoriteIcons();
}

async function fetchBackendFavorites() {
  try {
    const res = await fetch('/api/wishlist/items');
    const data = await res.json();
    if (data.success) {
      backendFavorites = (data.favorites || data.items || data.wishlist || []).map(item => item.id || item.product_id || item.pID);
    } else {
      backendFavorites = [];
    }
  } catch {
    backendFavorites = [];
  }
}

function isFav(id) {
  return backendFavorites.includes(id);
}

async function fetchProducts(containerId) {
  showLoading(containerId);
  try {
    const res = await fetch(API_URL);
    if (!res.ok) throw new Error();
    const products = await res.json();
    fetchedProducts = products;
    renderProducts(products, containerId);
  } catch {
    showError(containerId);
  }
}

// Update all heart icons after fetching backend favorites
async function updateAllFavoriteIcons() {
  await fetchBackendFavorites();
  document.querySelectorAll('.favorite-btn').forEach(btn => {
    const pid = parseInt(btn.getAttribute('data-product-id'));
    if (isFav(pid)) {
      btn.classList.add('active');
    } else {
      btn.classList.remove('active');
    }
  });
}

// On page load, update all favorite icons
if (document.querySelector('.favorite-btn')) {
  updateAllFavoriteIcons();
}

function toggleFavorite(productId) {
  let favs = getFavorites();
  if (favs.includes(productId)) {
    favs = favs.filter(id => id !== productId);
  } else {
    favs.push(productId);
  }
  saveFavorites(favs);
  renderProducts(fetchedProducts, detectContainer());
}

function addToCart(arg1, arg2) {
  let event = null;
  let productId = null;

  if (typeof arg1 === "object" && arg1 !== null && !Array.isArray(arg1)) {
    event = arg1;
    productId = typeof arg2 === "number" ? arg2 : parseInt(arg1.currentTarget?.dataset.productId || arg1.target?.dataset.productId, 10);
  } else {
    productId = arg1;
    event = arg2;
  }

  if (!productId) return;

  if (event && typeof event.stopPropagation === "function") {
    event.preventDefault?.();
    event.stopPropagation();
  }

  const sizeField = document.getElementById(`size-${productId}`);
  let size = sizeField?.value;

  if (!size) {
    if (sizeField?.tagName === "INPUT" && sizeField.type === "hidden" && sizeField.value) {
      size = sizeField.value;
    } else {
      alert("Please select a size.");
      sizeField?.focus?.();
      return;
    }
  }

  const cart = getCart();
  cart.push({ id: productId, size, qty: 1 });
  saveCart(cart);
  alert("✅ Added to cart!");
}

function detectContainer() {
  if (document.getElementById("all-products")) return "all-products";
  if (document.getElementById("featured-products")) return "featured-products";
  return null;
}

function displaySearchResults(products) {
  const searchResults = document.getElementById("searchResults");
  if (!searchResults) return;

  const productList = Array.isArray(products) ? products : [];

  if (!productList.length) {
    searchResults.innerHTML = `
      <div class="col-12">
        <div class="alert alert-info mb-0">No products found</div>
      </div>`;
    return;
  }

  const cardsHtml = productList.map(product => {
    const productId = product.id || product.pID || product.product_id;
    if (!productId) return "";

    const title = product.title || product.name || product.productName || "Product";
    const priceValue = parseFloat(product.price ?? product.productPrice ?? 0);
    const price = Number.isFinite(priceValue) ? priceValue.toFixed(2) : "0.00";
    const productUrl = product.url || product.productUrl || `/product/${productId}.html`;
    const safeProductUrl = productUrl.replace(/'/g, "\\'");
    const imageSrc = resolveProductImage(product);
    const sizes = normalizeSizes(product);

    const sizeMarkup = sizes.length
      ? `
        <select class="form-select form-select-sm mb-2 size-selector" id="size-${productId}" name="size-${productId}" onclick="event.stopPropagation();" aria-label="Select size for ${escapeHtml(title)}">
          <option value="" selected disabled>Select size</option>
          ${sizes.map(size => `<option value="${escapeHtml(size)}">${escapeHtml(size)}</option>`).join("")}
        </select>`
      : `<input type="hidden" id="size-${productId}" value="Default">`;

    return `
      <div class="col-lg-3 col-md-4 col-sm-6">
        <div class="product-card shadow-sm h-100"
             data-product-id="${productId}"
             data-product-name="${escapeHtml(title)}"
             data-product-price="${price}"
             data-product-url="${escapeHtml(productUrl)}"
             onclick="window.location.href='${safeProductUrl}'"
             style="cursor:pointer;">
          <div class="product-image-container position-relative overflow-hidden">
            <img src="${escapeHtml(imageSrc)}" class="product-image w-100" alt="${escapeHtml(title)}" onerror="this.onerror=null;this.src='/static/img/default.jpg';">
            <button class="quick-view-btn" onclick="event.stopPropagation(); window.location.href='${safeProductUrl}'">Quick View</button>
            <button class="favorite-btn" data-product-id="${productId}" onclick="addToWishlist(event, ${productId})">
              <i class="fas fa-heart"></i>
            </button>
          </div>
          <div class="product-info text-center mt-2">
            <h5 class="product-title mb-1 text-dark text-truncate fw-semibold">${escapeHtml(title)}</h5>
            <p class="product-price text-muted mb-0">EGP ${price}</p>
            <div class="mt-3">
              ${sizeMarkup}
              <button class="btn btn-dark w-100 add-to-cart" data-product-id="${productId}" onclick="addToCart(event, ${productId})">
                <i class="fas fa-shopping-cart me-2"></i>Add to Cart
              </button>
            </div>
          </div>
        </div>
      </div>`;
  }).filter(Boolean).join("");

  if (!cardsHtml) {
    searchResults.innerHTML = `
      <div class="col-12">
        <div class="alert alert-info mb-0">No products found</div>
      </div>`;
    return;
  }

  searchResults.innerHTML = cardsHtml;

  searchResults.querySelectorAll('.size-selector').forEach(select => {
    select.addEventListener('click', e => e.stopPropagation());
  });

  updateAllFavoriteIcons();
}

function initSearchToggle() {
  const toggle = document.getElementById("searchToggle");
  const searchBarContainer = document.getElementById("searchBarContainer");
  const searchInput = document.getElementById("searchInput");
  const searchResults = document.getElementById("searchResults");

  toggle?.addEventListener("click", function (e) {
    e.preventDefault();
    searchBarContainer?.classList.toggle("d-none");
    if (!searchBarContainer.classList.contains("d-none")) {
      setTimeout(() => searchInput?.focus(), 200);
    }
  });

  // Hide search bar when clicking outside
  document.addEventListener("click", (e) => {
    if (
      searchBarContainer &&
      !searchBarContainer.classList.contains("d-none") &&
      !searchBarContainer.contains(e.target) &&
      !toggle.contains(e.target)
    ) {
      searchBarContainer.classList.add("d-none");
    }
  });

  // Live search as user types
  searchInput?.addEventListener("input", function () {
    const query = this.value.trim();
    if (query.length === 0) {
      searchResults.innerHTML = "";
      searchResults.style.display = "none";
      return;
    }
    fetch(`${API_URL}?query=${encodeURIComponent(query)}`)
      .then(res => res.json())
      .then(results => {
        displaySearchResults(results);
        searchResults.style.display = "block";
      })
      .catch(() => {
        searchResults.innerHTML = `<p class="text-danger">Error loading results.</p>`;
        searchResults.style.display = "block";
      });
  });

  // Close on Escape
  searchInput?.addEventListener("keydown", function (e) {
    if (e.key === "Escape") {
      searchBarContainer.classList.add("d-none");
      searchResults.style.display = "none";
    }
  });
}

document.addEventListener("DOMContentLoaded", () => {
  // Cool Search Bar Toggle Logic
  const icon = document.getElementById('coolSearchIcon');
  const barWrapper = document.getElementById('coolSearchBarWrapper');
  const input = document.getElementById('coolSearchInput');
  const results = document.getElementById('coolSearchResults');
  let timeout = null;

  if (icon && barWrapper && input) {
    icon.addEventListener('click', function(e) {
      e.preventDefault();
      if (barWrapper.classList.contains('show')) {
        barWrapper.classList.remove('show');
        setTimeout(() => barWrapper.classList.add('d-none'), 300);
      } else {
        barWrapper.classList.remove('d-none');
        setTimeout(() => barWrapper.classList.add('show'), 10);
        setTimeout(() => input.focus(), 300);
      }
    });
    // Hide on Escape
    input.addEventListener('keydown', function(e) {
      if (e.key === 'Escape') {
        barWrapper.classList.remove('show');
        setTimeout(() => barWrapper.classList.add('d-none'), 300);
      }
    });
  }

  // Cool Search Bar Live Logic
  if (input && results) {
    input.addEventListener('input', function() {
      clearTimeout(timeout);
      const q = this.value.trim();
      if (q.length < 2) {
        results.style.display = 'none';
        results.innerHTML = '';
        return;
      }
      results.innerHTML = '<div style="padding:20px;text-align:center;"><span class="spinner-border"></span></div>';
      results.style.display = 'block';
      timeout = setTimeout(() => {
        fetch(`/api/search?q=${encodeURIComponent(q)}`)
          .then(res => res.json())
          .then(data => {
            if (!data.length) {
              results.innerHTML = '<div style="padding:20px;text-align:center;color:#888;">No products found</div>';
              return;
            }
            results.innerHTML = data.map(p => {
              let img = '';
              if (p.images && p.images.length > 0) {
                img = p.images[0];
              } else if (p.image) {
                img = p.image;
              } else if (p.image_url) {
                img = p.image_url;
              } else {
                img = '/static/img/default.jpg';
              }
              if (img && !img.startsWith('/static/')) {
                img = '/static/uploads/' + img;
              }
              return `
                <div class="cool-search-result-item" onclick="window.location='/product/${p.id}.html'">
                  <img src="${img}" class="cool-search-result-img" alt="" onerror="this.onerror=null;this.src='/static/img/default.jpg';">
                  <span class="cool-search-result-name">${p.name}</span>
                  <span class="cool-search-result-price">EGP ${p.price.toFixed(2)}</span>
                </div>
              `;
            }).join('');
          })
          .catch(() => {
            results.innerHTML = '<div style="padding:20px;text-align:center;color:#b12704;">Error loading results</div>';
          });
      }, 300);
    });

    // Hide results on blur
    input.addEventListener('blur', () => setTimeout(() => results.style.display = 'none', 200));
    input.addEventListener('focus', () => {
      if (results.innerHTML.trim()) results.style.display = 'block';
    });
  }

  // Existing product grid logic
  const path = window.location.pathname;
  if (path.includes("search.html")) {
    const query = new URLSearchParams(window.location.search).get("query");
    if (query) fetch(`${API_URL}?query=${encodeURIComponent(query)}`)
      .then(res => res.json())
      .then(displaySearchResults);
  } else {
    const containerId = detectContainer();
    const isShopPage = path.endsWith("/shop.html") || path === "/shop.html";
    if (containerId && !isShopPage) {
      fetchProducts(containerId);
    }
  }

  // --- CART PAGE LOGIC ---
  if (window.location.pathname.endsWith('/cart.html')) {
    // Quantity adjustment
    document.querySelectorAll('.quantity-btn').forEach(function(btn) {
      btn.addEventListener('click', function() {
        const itemId = this.getAttribute('data-item-id');
        const action = this.getAttribute('data-action');
        const input = document.querySelector(`.quantity-input[data-item-id="${itemId}"]`);
        let quantity = parseInt(input.value);
        if (action === 'increase') {
          quantity += 1;
        } else if (action === 'decrease' && quantity > 1) {
          quantity -= 1;
        }
        input.value = quantity;
        updateCartItem(itemId, quantity);
      });
    });
    // Direct quantity input
    document.querySelectorAll('.quantity-input').forEach(function(input) {
      input.addEventListener('change', function() {
        const itemId = this.getAttribute('data-item-id');
        let quantity = parseInt(this.value);
        if (isNaN(quantity) || quantity < 1) {
          quantity = 1;
          this.value = 1;
        }
        updateCartItem(itemId, quantity);
      });
    });
    // Remove item
    document.querySelectorAll('.remove-item').forEach(function(btn) {
      btn.addEventListener('click', function() {
        const itemId = this.getAttribute('data-item-id');
        if (confirm('Are you sure you want to remove this item from your cart?')) {
          removeCartItem(itemId);
        }
      });
    });
    function updateCartItem(itemId, quantity) {
      fetch('/api/update-cart-item', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ cart_item_id: itemId, quantity: quantity })
      })
      .then(res => res.json())
      .then(response => {
        if (!response.success) throw new Error(response.message || 'Update failed');
        // Update subtotal and total in the DOM
        const row = document.querySelector(`.quantity-input[data-item-id="${itemId}"]`).closest('tr');
        const price = parseFloat(row.querySelector('td:nth-child(4)').textContent.replace('EGP', '').trim());
        const newTotal = (price * quantity).toFixed(2);
        row.querySelector('td:nth-child(5)').textContent = 'EGP ' + newTotal;
        updateGrandTotal();
      })
      .catch(err => alert('Error updating cart item: ' + err.message));
    }
    function removeCartItem(itemId) {
      fetch('/api/remove-cart-item', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ cart_item_id: itemId })
      })
      .then(res => res.json())
      .then(response => {
        if (!response.success) throw new Error(response.message || 'Remove failed');
        // Remove the row and update totals
        const row = document.querySelector(`.remove-item[data-item-id="${itemId}"]`).closest('tr');
        row.parentNode.removeChild(row);
        updateGrandTotal();
        // If no items left, reload to show empty cart message
        if (document.querySelectorAll('tbody tr').length === 0) {
          location.reload();
        }
      })
      .catch(err => alert('Error removing item from cart: ' + err.message));
    }
    function updateGrandTotal() {
      let grandTotal = 0;
      document.querySelectorAll('tbody tr').forEach(function(row) {
        const totalText = row.querySelector('td:nth-child(5)').textContent.replace('EGP', '').trim();
        grandTotal += parseFloat(totalText) || 0;
      });
      document.querySelectorAll('.order-summary span').forEach(function(span) {
        if (span.textContent.trim() === 'Subtotal:') {
          span.nextElementSibling.textContent = 'EGP ' + grandTotal.toFixed(2);
        }
        if (span.textContent.trim() === 'Total:') {
          span.nextElementSibling.textContent = 'EGP ' + grandTotal.toFixed(2);
        }
      });
    }
  }
});

window.addToWishlist = function(event, productId) {
  event.stopPropagation();
  fetch('/add-to-wishlist', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ product_id: productId })
  })
  .then(res => res.json())
  .then(data => {
    if (data.success) {
      updateAllFavoriteIcons();
    } else {
      alert(data.message || 'Could not add to wishlist.');
    }
  })
  .catch(() => alert('Could not add to wishlist.'));
}

// Add CSS for .favorite-btn.active to make the heart red
if (!document.getElementById('favorite-btn-active-style')) {
  const style = document.createElement('style');
  style.id = 'favorite-btn-active-style';
  style.innerHTML = `.favorite-btn.active i { color: #dc3545 !important; }`;
  document.head.appendChild(style);
}
