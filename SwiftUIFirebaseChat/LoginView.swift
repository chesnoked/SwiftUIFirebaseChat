//
//  ContentView.swift
//  SwiftUIFirebaseChat
//
//  Created by Evgeniy Safin on 04.07.2022.
//

import SwiftUI
import Firebase

class FirebaseManager: NSObject {
    
    let auth: Auth
    static let shared = FirebaseManager()
    
    override init() {
        FirebaseApp.configure()
        self.auth = Auth.auth()
        super.init()
    }
}

struct LoginView: View {
    
    @State var isLoginMode = false
    @State var email = ""
    @State var password = ""
    @State var loginStatusMessage = ""
    
//    init() {
//        //FirebaseApp.configure()
//    }
    
    var body: some View {
        
        NavigationView {
            
            ScrollView {
                
                VStack(spacing: 16) {
                    Picker(selection: $isLoginMode, label: Text("Picker here"), content: {
                        Text("Login")
                            .tag(true)
                        
                        Text("Create Account")
                            .tag(false)
                    })
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if !isLoginMode {
                        Button(action: {
                            //
                        }, label: {
                            Image(systemName: "person.fill")
                                .font(.system(size: 64))
                                .padding()
                        })
                    }
                    
                    Group {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        SecureField("Password", text: $password)
                    }
                    .padding(12)
                    .background(Color.white)
                    
                    Button(action: {
                        handleAction()
                    }, label: {
                        Text(isLoginMode ? "Log In" : "Create Account")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                    })
                    
                    Text(loginStatusMessage)
                        .foregroundColor(.red)
                    
                }
                .padding()
            }
            .navigationTitle(isLoginMode ? "Log In" : "Create Account")
        }
        .background(
            Color(.init(white: 0, alpha: 0.05))
                .ignoresSafeArea()
        )
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func loginUser() {
        FirebaseManager.shared.auth.signIn(
            withEmail: email,
            password: password) { result, err in
                if let err = err {
                    loginStatusMessage = "Failed to login user: \(err)"
                    //print(loginStatusMessage)
                    return
                }
                loginStatusMessage = "Successfully logged in as user: \(result?.user.uid ?? "")"
            }
    }
    
    private func handleAction() {
        if isLoginMode {
            loginUser()
        } else {
            createNewAccount()
        }
    }
    
    private func createNewAccount() {
        FirebaseManager.shared.auth.createUser(
            withEmail: email,
            password: password) { result, err in
                if let err = err {
                    loginStatusMessage = "Failed to create user: \(err)"
                    //print(loginStatusMessage)
                    return
                }
                loginStatusMessage = "Successfully created user: \(result?.user.uid ?? "")"
                //print(loginStatusMessage)
            }
        print(loginStatusMessage)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
