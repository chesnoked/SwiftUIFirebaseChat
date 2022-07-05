//
//  ContentView.swift
//  SwiftUIFirebaseChat
//
//  Created by Evgeniy Safin on 04.07.2022.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

class FirebaseManager: NSObject {
    
    let auth: Auth
    let storage: Storage
    let firestore: Firestore
    
    static let shared = FirebaseManager()
    
    override init() {
        FirebaseApp.configure()
        
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        self.firestore = Firestore.firestore()
        
        super.init()
    }
}

struct LoginView: View {
    
    @State var isLoginMode = false
    @State var email = ""
    @State var password = ""
    @State var loginStatusMessage = ""
    
    @State var shouldShowImagePicker: Bool = false
    @State var image: UIImage?
    
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
                            shouldShowImagePicker.toggle()
                        }, label: {
                            
                            VStack {
                                if let image = self.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 128, height: 128)
                                        .cornerRadius(64)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 64))
                                        .padding()
                                        .foregroundColor(Color(.label))
                                }
                            }
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 3)
                            )
                            
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
        .fullScreenCover(
            isPresented: $shouldShowImagePicker,
            onDismiss: nil) {
                ImagePicker(image: $image)
            }
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
                
                // Load image to Firebase Storage
                persistImageToStorage()
            }
        print(loginStatusMessage)
    }
    
    private func persistImageToStorage() {
        
        //let filename = UUID().uuidString
        
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else { return }
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
                self.loginStatusMessage = "Failed to push image to Storage: \(err)"
                return
            }
            
            ref.downloadURL { url, err in
                if let err = err {
                    self.loginStatusMessage = "Failed to retrieve downloadURL: \(err)"
                    return
                }
                
                self.loginStatusMessage = "Successfully stored image with url: \(url?.absoluteString ?? "")"
                print(url?.absoluteString)
                
                guard let url = url else { return }
                self.storeUserInformation(imageProfileUrl: url)
            }
        }
    }
    
    private func storeUserInformation(imageProfileUrl: URL) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let userData = ["email": self.email, "uid": uid, "profileImageUrl": imageProfileUrl.absoluteString]
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).setData(userData) { err in
                if let err = err {
                    loginStatusMessage = "\(err)"
                    print(loginStatusMessage)
                    return
                }
                
                print("Success")
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
