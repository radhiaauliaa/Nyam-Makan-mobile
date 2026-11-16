const { initializeApp } = require("firebase-admin/app");
const {
  DocumentReference,
  GeoPoint,
  Timestamp,
  getFirestore,
} = require("firebase-admin/firestore");
const { HttpsError, onCall } = require("firebase-functions/v2/https");

initializeApp();

const firestore = getFirestore();
const excludedCollectionName = "users";
const maxContextCharacters = 48000;

exports.getChatbotDatabaseContext = onCall(
  {
    region: "asia-southeast2",
    timeoutSeconds: 540,
    memory: "1GiB",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Silakan login terlebih dahulu.");
    }

    if (request.auth.token.admin !== true) {
      throw new HttpsError(
        "permission-denied",
        "Akses chatbot seluruh database hanya tersedia untuk admin.",
      );
    }

    const question = request.data?.question;
    if (typeof question !== "string" || question.trim().length === 0) {
      throw new HttpsError("invalid-argument", "Pertanyaan tidak boleh kosong.");
    }
    if (question.length > 1000) {
      throw new HttpsError(
        "invalid-argument",
        "Pertanyaan terlalu panjang (maksimal 1000 karakter).",
      );
    }

    try {
      const documents = [];
      const rootCollections = await firestore.listCollections();
      await Promise.all(
        rootCollections
          .filter((collection) => !containsUsersCollection(collection.path))
          .map((collection) => collectCollection(collection, documents)),
      );

      const keywords = extractKeywords(question);
      const matches = documents
        .map((document) => ({
          ...document,
          score: scoreDocument(document.text, keywords),
        }))
        .filter((document) => document.score > 0)
        .sort(
          (left, right) =>
            right.score - left.score || left.path.localeCompare(right.path),
        );

      let context = "";
      let includedDocuments = 0;
      for (const document of matches) {
        const separator = context.length === 0 ? "" : "\n";
        const remainingCharacters =
          maxContextCharacters - context.length - separator.length;
        if (remainingCharacters <= 0) break;

        const text =
          document.text.length > remainingCharacters
            ? document.text.slice(0, remainingCharacters)
            : document.text;
        context += `${separator}${text}`;
        includedDocuments += 1;
        if (text.length < document.text.length) break;
      }

      const truncationNotice =
        includedDocuments < matches.length
          ? "\n[Hasil relevan dipotong agar muat dalam konteks AI.]"
          : "";

      return {
        context:
          `Dokumen non-users diperiksa: ${documents.length}. ` +
          `Dokumen relevan: ${includedDocuments}.\n` +
          (context || "Tidak ditemukan dokumen yang cocok.") +
          truncationNotice,
      };
    } catch (error) {
      console.error("Gagal mencari konteks database chatbot:", error);
      throw new HttpsError(
        "internal",
        "Gagal mencari data database untuk chatbot.",
      );
    }
  },
);

async function collectCollection(collection, documents) {
  if (containsUsersCollection(collection.path)) return;

  const snapshot = await collection.get();
  for (const document of snapshot.docs) {
    const data = serializeValue(document.data());
    const text = JSON.stringify({
      collection: collection.path,
      documentId: document.id,
      data,
    });

    documents.push({ path: `${collection.path}/${document.id}`, text });

    const subcollections = await document.ref.listCollections();
    await Promise.all(
      subcollections
        .filter((subcollection) => !containsUsersCollection(subcollection.path))
        .map((subcollection) => collectCollection(subcollection, documents)),
    );
  }
}

function containsUsersCollection(path) {
  return path
    .split("/")
    .some((segment) => segment.toLowerCase() === excludedCollectionName);
}

function serializeValue(value) {
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (value instanceof GeoPoint) {
    return { latitude: value.latitude, longitude: value.longitude };
  }
  if (value instanceof DocumentReference) return value.path;
  if (Array.isArray(value)) return value.map(serializeValue);
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value).map(([key, nestedValue]) => [
        key,
        serializeValue(nestedValue),
      ]),
    );
  }
  return value;
}

function extractKeywords(question) {
  const stopWords = new Set([
    "ada",
    "apa",
    "atau",
    "bagaimana",
    "bisa",
    "dan",
    "dari",
    "dengan",
    "di",
    "ke",
    "mana",
    "mau",
    "saya",
    "tolong",
    "untuk",
    "yang",
  ]);
  return [
    ...new Set(
      question
        .toLowerCase()
        .match(/[a-z0-9]+/g)
        .filter((word) => word.length > 2 && !stopWords.has(word)),
    ),
  ];
}

function scoreDocument(text, keywords) {
  if (keywords.length === 0) return 1;
  const normalizedText = text.toLowerCase();
  return keywords.reduce(
    (score, keyword) => score + (normalizedText.includes(keyword) ? 1 : 0),
    0,
  );
}
