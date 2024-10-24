import React from 'react';
import { Authenticator } from '@aws-amplify/ui-react';
import '@aws-amplify/ui-react/styles.css';

function Login() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            CCFS Blog Login
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Share your island food adventures
          </p>
        </div>
        <Authenticator>
          {({ signOut, user }) => (
            <div className="text-center">
              <p className="mb-4">Welcome, {user.attributes.email}</p>
              <button
                onClick={signOut}
                className="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600"
              >
                Sign Out
              </button>
            </div>
          )}
        </Authenticator>
      </div>
    </div>
  );
}

export default Login;