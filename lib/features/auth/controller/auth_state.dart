class AuthState {
  final bool loading;
  final String? error;
  final String? token;
  final bool bootstrapped;
  final String? email;
  final bool? isVerified;

  const AuthState({
    this.loading = false,
    this.error,
    this.token,
    this.bootstrapped = false,
    this.email,
    this.isVerified,
  });

  static const _unset = Object();

  AuthState copyWith({
    bool? loading,
    Object? error = _unset,
    Object? token = _unset,
    bool? bootstrapped,
    Object? email = _unset,
    Object? isVerified = _unset, // <- dùng sentinel cho nullable
  }) {
    return AuthState(
      loading: loading ?? this.loading,
      error: identical(error, _unset) ? this.error : error as String?,
      token: identical(token, _unset) ? this.token : token as String?,
      bootstrapped: bootstrapped ?? this.bootstrapped,
      email: identical(email, _unset) ? this.email : email as String?,
      isVerified: identical(isVerified, _unset)
          ? this.isVerified
          : isVerified as bool?,
    );
  }
}
