//
//  GlemtPasswordView.swift
//  IshojUngdom
//
//  View: Nulstil adgangskode (US 45)
//

import SwiftUI

struct GlemtPasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var email: String = ""
    @State private var sender: Bool = false
    @State private var emailSendt: Bool = false
    @State private var fejlBesked: String? = nil
    
    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
            
            VStack(spacing: 24) {
                if emailSendt {
                    // Bekræftelse
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.green)
                            .padding(.top, 40)
                        
                        Text("Email sendt!")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Vi har sendt instruktioner til at nulstille din adgangskode til \(email). Tjek din indbakke.")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Text("Tilbage til login")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .glassEffect(.regular.interactive().tint(.blue.opacity(0.4)), in: Capsule())
                        }
                    }
                } else {
                    // Indtast email
                    Text("Glemt adgangskode?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 40)
                    
                    Text("Indtast din email, så sender vi dig en email med instruktioner.")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 10)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .foregroundColor(.white.opacity(0.85))
                            .font(.subheadline)
                        
                        TextField("", text: $email,
                                  prompt: Text("din@email.dk").foregroundColor(.white.opacity(0.4)))
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .tint(.white)
                            .textContentType(.none)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(.horizontal, 18).padding(.vertical, 16)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                    }
                    
                    if let fejl = fejlBesked {
                        Text(fejl).foregroundColor(.red).font(.footnote)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: { Task { await sendEmail() } }) {
                        if sender {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .glassEffect(.regular.interactive(), in: Capsule())
                        } else {
                            Text("Send nulstil-email")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .glassEffect(.regular.interactive().tint(.blue.opacity(0.4)), in: Capsule())
                        }
                    }
                    .disabled(email.isEmpty || sender)
                    .opacity(email.isEmpty ? 0.5 : 1.0)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    private func sendEmail() async {
        sender = true
        fejlBesked = nil
        let ok = await authViewModel.sendNulstilEmail(email: email)
        sender = false
        if ok {
            emailSendt = true
        } else {
            fejlBesked = authViewModel.errorMessage
        }
    }
}
