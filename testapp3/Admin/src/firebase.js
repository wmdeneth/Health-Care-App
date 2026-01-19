import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
import { getFirestore } from "firebase/firestore"; // 1. Add this import

const firebaseConfig = {
  apiKey: "AIzaSyDWKNgq7SH9rQhrCavcaemgq4YpHtOjhN0",
  authDomain: "testapp3-2b6df.firebaseapp.com",
  projectId: "testapp3-2b6df",
  storageBucket: "testapp3-2b6df.firebasestorage.app",
  messagingSenderId: "821854204321",
  appId: "1:821854204321:web:a6a11aac0f20c4cbf9dbe0",
  measurementId: "G-N8XB3EYPPF"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);

// 2. Initialize Firestore and export it for use in other files
export const db = getFirestore(app);