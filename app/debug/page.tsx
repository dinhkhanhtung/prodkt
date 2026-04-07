'use client';

import { useEffect, useState } from 'react';

export default function DebugFirebase() {
  const [config, setConfig] = useState<any>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    // Check env variables
    setConfig({
      apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY?.slice(0, 10) + '...',
      authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
      projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
      hasConfig: !!process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
    });
  }, []);

  const testFirebase = async () => {
    try {
      const { auth } = await import('@/lib/firebase');
      const { createUserWithEmailAndPassword } = await import('firebase/auth');
      
      // Try to create a test user
      await createUserWithEmailAndPassword(auth, 'test@example.com', 'password123');
      alert('Firebase working!');
    } catch (err: any) {
      setError(err.code + ': ' + err.message);
      console.error(err);
    }
  };

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Firebase Debug</h1>
      
      <div className="bg-gray-100 p-4 rounded mb-4">
        <h2 className="font-semibold">Config:</h2>
        <pre className="text-sm">{JSON.stringify(config, null, 2)}</pre>
      </div>

      {error && (
        <div className="bg-red-100 p-4 rounded mb-4 text-red-700">
          <h2 className="font-semibold">Error:</h2>
          <p>{error}</p>
        </div>
      )}

      <button 
        onClick={testFirebase}
        className="px-4 py-2 bg-blue-600 text-white rounded"
      >
        Test Firebase Auth
      </button>

      <div className="mt-8 text-sm text-gray-600">
        <h2 className="font-semibold mb-2">Common fixes:</h2>
        <ul className="list-disc pl-5 space-y-1">
          <li>Enable Email/Password in Firebase Console → Authentication</li>
          <li>Add your domain to Authorized domains</li>
          <li>Check API key restrictions in Google Cloud Console</li>
        </ul>
      </div>
    </div>
  );
}
