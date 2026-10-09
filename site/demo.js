"use strict";

const categories = [
  { id: "food", label: "Ăn uống", color: "#176b58", phrases: ["an trua", "an toi", "ca phe", "cafe", "tra sua", "com", "bun", "pho"] },
  { id: "study", label: "Học tập", color: "#456ca5", phrases: ["hoc phi", "sach", "giao trinh", "khoa hoc"] },
  { id: "travel", label: "Di chuyển", color: "#9b651b", phrases: ["taxi", "grab", "xang", "ve xe", "ve tau"] },
  { id: "gear", label: "Mua sắm", color: "#9b5b70", phrases: ["mua sam", "ban phim", "tai nghe", "quan ao"] },
  { id: "entertainment", label: "Giải trí", color: "#715aa4", phrases: ["xem phim", "rap phim", "game", "karaoke"] },
  { id: "other", label: "Khác", color: "#68766c", phrases: [] },
];
const samples = {
  food: { description: "Thanh toan an trua", amount: "150000" },
  study: { description: "Dong hoc phi", amount: "450000" },
  unknown: { description: "Chuyen tien", amount: "200000" },
};
const initialRecords = [
  { description: "Thanh toan an trua", amount: 150000, category: "food", direction: "expense" },
  { description: "Dong hoc phi", amount: 450000, category: "study", direction: "expense" },
  { description: "Chuyen tien", amount: 200000, category: "other", direction: "expense" },
  { description: "Hoan tien", amount: 1200000, category: "other", direction: "income" },
];
const currency = new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND", maximumFractionDigits: 0 });
const form = document.querySelector("#demo-form");
const description = document.querySelector("#description");
const amount = document.querySelector("#amount");
const category = document.querySelector("#category");
const direction = document.querySelector("#direction");
const suggestion = document.querySelector("#suggestion");
const status = document.querySelector("#form-status");
let records = initialRecords.map(record => ({ ...record }));
let selectedCategory = null;

function normalize(text) {
  return text.normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/đ/g, "d").replace(/Đ/g, "D").toLowerCase().replace(/[^a-z0-9]+/g, " ").trim();
}

function suggestCategory() {
  const text = ` ${normalize(description.value)} `;
  const matches = categories.filter(item => item.phrases.some(phrase => text.includes(` ${phrase} `)));
  category.value = matches.length === 1 ? matches[0].id : "";
  suggestion.textContent = matches.length === 1
    ? `Gợi ý từ nội dung: ${matches[0].label}. Bạn có thể sửa lại.`
    : "Chưa có gợi ý chắc chắn. Hãy tự chọn danh mục trước khi thêm.";
}

function setSample(key) {
  description.value = samples[key].description;
  amount.value = samples[key].amount;
  direction.value = "expense";
  document.querySelectorAll("[data-sample]").forEach(button => button.setAttribute("aria-pressed", String(button.dataset.sample === key)));
  amount.setCustomValidity("");
  status.textContent = "";
  suggestCategory();
}

function selectCategory(id) {
  selectedCategory = id;
  const group = categories.find(item => item.id === id);
  const value = records.filter(record => record.direction === "expense" && (!id || record.category === id)).reduce((sum, record) => sum + record.amount, 0);
  document.querySelector("#selection-label").textContent = group ? group.label : "Tổng chi";
  document.querySelector("#selection-value").textContent = currency.format(value);
  document.querySelectorAll(".legend button").forEach(button => button.setAttribute("aria-pressed", String(button.dataset.category === id)));
}

function render() {
  const expenses = records.filter(record => record.direction === "expense");
  const expenseTotal = expenses.reduce((sum, record) => sum + record.amount, 0);
  const incomeTotal = records.filter(record => record.direction === "income").reduce((sum, record) => sum + record.amount, 0);
  document.querySelector("#expense-total").textContent = currency.format(expenseTotal);
  document.querySelector("#income-total").textContent = currency.format(incomeTotal);
  document.querySelector("#net-total").textContent = currency.format(incomeTotal - expenseTotal);
  const chart = document.querySelector("#donut");
  chart.querySelectorAll(".donut-segment").forEach(segment => segment.remove());
  const legend = document.querySelector("#legend");
  legend.replaceChildren();
  const circumference = 2 * Math.PI * 48;
  let offset = 0;
  categories.forEach(item => {
    const value = expenses.filter(record => record.category === item.id).reduce((sum, record) => sum + record.amount, 0);
    if (value === 0) return;
    const fraction = value / expenseTotal;
    const circle = document.createElementNS("http://www.w3.org/2000/svg", "circle");
    circle.setAttribute("class", "donut-segment");
    circle.setAttribute("cx", "60"); circle.setAttribute("cy", "60"); circle.setAttribute("r", "48");
    circle.setAttribute("stroke", item.color);
    circle.setAttribute("stroke-dasharray", `${fraction * circumference} ${circumference}`);
    circle.setAttribute("stroke-dashoffset", String(-offset));
    circle.setAttribute("aria-hidden", "true");
    offset += fraction * circumference;
    chart.append(circle);
    const button = document.createElement("button");
    button.type = "button";
    button.dataset.category = item.id;
    button.setAttribute("aria-label", `${item.label}: ${currency.format(value)}, ${Math.round(fraction * 100)} phần trăm`);
    const name = document.createElement("span"); name.className = "name";
    const dot = document.createElement("span"); dot.className = "dot"; dot.style.background = item.color; dot.setAttribute("aria-hidden", "true");
    const label = document.createElement("span"); label.textContent = item.label;
    name.append(dot, label);
    const percent = document.createElement("span"); percent.className = "percent"; percent.textContent = `${Math.round(fraction * 100)}%`;
    button.append(name, percent);
    button.addEventListener("click", () => selectCategory(selectedCategory === item.id ? null : item.id));
    legend.append(button);
  });
  selectCategory(selectedCategory);
  const recent = document.querySelector("#recent");
  recent.replaceChildren();
  records.slice(-3).reverse().forEach(record => {
    const li = document.createElement("li");
    const details = document.createElement("div");
    const text = document.createElement("span"); text.className = "description"; text.textContent = record.description;
    const sub = document.createElement("span"); sub.className = "category"; sub.textContent = `${record.direction === "income" ? "Khoản thu" : "Khoản chi"} · ${categories.find(item => item.id === record.category).label}`;
    details.append(text, sub);
    const value = document.createElement("strong"); value.textContent = `${record.direction === "income" ? "+" : "−"}${currency.format(record.amount)}`;
    li.append(details, value); recent.append(li);
  });
}

description.addEventListener("input", () => {
  document.querySelectorAll("[data-sample]").forEach(button => button.setAttribute("aria-pressed", "false"));
  suggestCategory();
});
amount.addEventListener("input", () => amount.setCustomValidity(""));
document.querySelectorAll("[data-sample]").forEach(button => button.addEventListener("click", () => setSample(button.dataset.sample)));
document.querySelector("#reset-demo").addEventListener("click", () => {
  records = initialRecords.map(record => ({ ...record }));
  selectedCategory = null;
  setSample("food");
  render();
  status.textContent = "Đã khôi phục dữ liệu mẫu ban đầu.";
});
form.addEventListener("submit", event => {
  event.preventDefault();
  const raw = amount.value.trim();
  const validGrouping = /^(?:\d+|\d{1,3}(?:[.]\d{3})+|\d{1,3}(?:[,]\d{3})+|\d{1,3}(?: \d{3})+)$/.test(raw);
  const value = validGrouping ? Number(raw.replace(/[., ]/g, "")) : NaN;
  if (!Number.isSafeInteger(value) || value <= 0 || value > 100000000000) {
    amount.setCustomValidity("Nhập số tiền nguyên dương tối đa 100 tỷ VND, ví dụ 150000 hoặc 150.000.");
    amount.reportValidity();
    return;
  }
  amount.setCustomValidity("");
  if (!form.reportValidity()) return;
  records.push({ description: description.value.trim(), amount: value, category: category.value, direction: direction.value });
  selectedCategory = null;
  render();
  status.textContent = `Đã thêm ${currency.format(value)} vào dữ liệu dùng thử. Chưa lưu vào ứng dụng Android.`;
});
suggestCategory();
render();
