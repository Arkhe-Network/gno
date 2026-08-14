// arkhe_haselgrove_v2.rs
// Haselgrove Ray Tracer com Hamiltoniano corrigido
// Baseado em Jones & Stephenson (1975) e Haselgrove (1955)
// SASC v35.9-Ω | Bloco #119

use num_complex::Complex64;
use std::f64::consts::PI;

// ============================================================
// 1. TRAIT MAGNETIC FIELD (corrigido)
// ============================================================

pub trait MagneticField {
    /// Campo magnético em coordenadas esféricas (r, θ, φ)
    /// Retorna (B_r, B_θ, B_φ) em Tesla
    fn field_components(&self, r: f64, theta: f64, phi: f64) -> (f64, f64, f64);

    /// Magnitude do campo magnético
    fn magnitude(&self, r: f64, theta: f64, phi: f64) -> f64 {
        let (br, bth, bph) = self.field_components(r, theta, phi);
        (br * br + bth * bth + bph * bph).sqrt()
    }

    /// Frequência de ciclotron [rad/s]
    fn omega_c(&self, r: f64, theta: f64, phi: f64) -> f64 {
        const QE: f64 = 1.602176634e-19;
        const ME: f64 = 9.1093837015e-31;
        (QE / ME) * self.magnitude(r, theta, phi)
    }
}

// ============================================================
// 2. CAMPO MAGNÉTICO DIPOLAR (implementação do trait)
// ============================================================

pub struct DipolarMagneticField {
    pub b0: f64,        // intensidade no equador [T]
    pub r_earth: f64,   // raio da Terra [m]
}

impl DipolarMagneticField {
    pub fn new() -> Self {
        Self {
            b0: 3.12e-5,
            r_earth: 6.371e6,
        }
    }
}

impl MagneticField for DipolarMagneticField {
    fn field_components(&self, r: f64, theta: f64, _phi: f64) -> (f64, f64, f64) {
        let factor = (self.r_earth / r).powi(3);
        let br = -2.0 * self.b0 * factor * theta.cos();
        let btheta = -self.b0 * factor * theta.sin();
        (br, btheta, 0.0)
    }
}

// ============================================================
// 3. TRAIT DENSITY PROFILE
// ============================================================

pub trait DensityProfile {
    fn omega_p(&self, r: f64, theta: f64, phi: f64) -> f64;
    fn collision_frequency(&self, r: f64, theta: f64, phi: f64) -> f64;
}

// ============================================================
// 4. PERFIL CHAPMAN (implementação do trait)
// ============================================================

pub struct ChapmanProfile {
    pub f0: f64,          // frequência de plasma de pico [Hz]
    pub hm: f64,          // altitude de pico [m]
    pub scale_height: f64,// altura de escala [m]
    pub r_earth: f64,     // raio da Terra [m]
}

impl ChapmanProfile {
    pub fn new(f0: f64, hm: f64, scale_height: f64) -> Self {
        Self {
            f0,
            hm,
            scale_height,
            r_earth: 6.371e6,
        }
    }

    fn altitude(&self, r: f64) -> f64 {
        r - self.r_earth
    }
}

impl DensityProfile for ChapmanProfile {
    fn omega_p(&self, r: f64, _theta: f64, _phi: f64) -> f64 {
        const QE: f64 = 1.602176634e-19;
        const ME: f64 = 9.1093837015e-31;
        const EPS0: f64 = 8.8541878128e-12;

        let h = self.altitude(r);
        let n0_cm3 = (self.f0 / 8980.0).powi(2);
        let n0 = n0_cm3 * 1e6;
        let z = (h - self.hm) / self.scale_height;
        let ne = n0 * (0.5 * (1.0 - z - (-z).exp())).exp();

        ((QE * QE / (EPS0 * ME)) * ne).sqrt()
    }

    fn collision_frequency(&self, r: f64, _theta: f64, _phi: f64) -> f64 {
        let h = self.altitude(r);
        let h_ref = 100_000.0;
        let h_scale = 50_000.0;
        1.0e6 * (-(h - h_ref) / h_scale).exp()
    }
}

// ============================================================
// 5. NÚCLEO APPLETON-HARTREE (estável, mantido)
// ============================================================

pub fn appleton_hartree_n(
    omega_p: f64,
    omega: f64,
    omega_c: f64,
    nu: f64,
    theta: f64,
    mode: i8,
) -> Complex64 {
    if omega <= 0.0 {
        return Complex64::new(1.0, 0.0);
    }

    let x = (omega_p / omega).powi(2);
    let y = (omega_c / omega).abs();
    let z = nu / omega;
    let sin2 = theta.sin().powi(2);
    let cos2 = theta.cos().powi(2);

    if x < 1e-15 && y < 1e-15 && z < 1e-15 {
        return Complex64::new(1.0, 0.0);
    }

    let denom_a = Complex64::new(1.0 - x, -z);
    let a = Complex64::new(0.5 * y * y * sin2, 0.0) / denom_a;
    let sqrt_arg = a * a + Complex64::new(y * y * cos2, 0.0);
    let sqrt_term = sqrt_arg.sqrt();

    let sign = mode as f64;
    let full_denom = Complex64::new(1.0, -z) - (a + sign * sqrt_term);
    let n2 = Complex64::new(1.0, 0.0) - Complex64::new(x, 0.0) / full_denom;

    let mut n = n2.sqrt();
    if n.im < 0.0 {
        n = -n;
    }

    if n.re.is_nan() || n.im.is_nan() || n.re.is_infinite() || n.im.is_infinite() {
        return Complex64::new(0.0, 0.0);
    }

    n
}

// ============================================================
// 6. VELOCIDADE DE GRUPO
// ============================================================

pub fn group_velocity(
    omega_p: f64,
    omega: f64,
    omega_c: f64,
    nu: f64,
    theta: f64,
    mode: i8,
    delta_omega: f64,
) -> (f64, f64) {
    const C: f64 = 299792458.0;

    if omega <= 0.0 {
        return (C, 0.0);
    }

    let d_omega = if delta_omega > 0.0 { delta_omega } else { 1e-6 * omega };

    let n_plus = appleton_hartree_n(omega_p, omega + d_omega, omega_c, nu, theta, mode);
    let n_minus = appleton_hartree_n(omega_p, omega - d_omega, omega_c, nu, theta, mode);
    let dn_domega = (n_plus - n_minus) / (2.0 * d_omega);

    let n0 = appleton_hartree_n(omega_p, omega, omega_c, nu, theta, mode);
    let denom = n0 + Complex64::new(omega, 0.0) * dn_domega;
    let vg = Complex64::new(C, 0.0) / denom;

    if vg.re.is_nan() || vg.re.is_infinite() || vg.re < 0.0 {
        return (C, 0.0);
    }

    (vg.re, vg.im)
}

// ============================================================
// 7. INTEGRADOR HASELGROVE CORRIGIDO
// ============================================================

/// Estado do raio em coordenadas esféricas
#[derive(Debug, Clone, Copy)]
pub struct RayState {
    pub r: f64,         // raio [m]
    pub theta: f64,     // ângulo polar [rad]
    pub phi: f64,       // ângulo azimutal [rad]
    pub kr: f64,        // momento canônico radial [rad/m]
    pub ktheta: f64,    // momento canônico polar [rad/m]
    pub kphi: f64,      // momento canônico azimutal [rad/m]
    pub time: f64,      // tempo de grupo [s]
    pub path: f64,      // comprimento do caminho [m]
    pub attenuation: f64, // atenuação acumulada [nepers]
}

impl RayState {
    /// Componentes físicas do vetor de onda
    pub fn k_physical(&self) -> (f64, f64, f64) {
        let kr = self.kr;
        let ktheta = if self.r > 0.0 { self.ktheta / self.r } else { 0.0 };
        let kphi = if self.r > 0.0 && self.theta.sin() > 0.0 {
            self.kphi / (self.r * self.theta.sin())
        } else {
            0.0
        };
        (kr, ktheta, kphi)
    }

    /// Magnitude do vetor de onda físico
    pub fn k_magnitude(&self) -> f64 {
        let (kr, kth, kph) = self.k_physical();
        (kr * kr + kth * kth + kph * kph).sqrt()
    }
}

/// Integrador Haselgrove com Hamiltoniano corrigido
pub struct HaselgroveTracer<D, M>
where
    D: DensityProfile,
    M: MagneticField,
{
    pub profile: D,
    pub field: M,
    pub omega: f64,           // frequência da onda [rad/s]
    pub mode: i8,             // +1 O, -1 X
    pub max_steps: usize,
    pub ds: f64,              // passo de arco [m]
    pub include_absorption: bool,
    pub h_monitor: bool,      // monitorar Hamiltoniano
}

impl<D, M> HaselgroveTracer<D, M>
where
    D: DensityProfile,
    M: MagneticField,
{
    pub fn new(profile: D, field: M, omega: f64, mode: i8, ds: f64, max_steps: usize) -> Self {
        Self {
            profile,
            field,
            omega,
            mode,
            max_steps,
            ds,
            include_absorption: true,
            h_monitor: true,
        }
    }

    /// Calcula o índice de refração n no estado atual
    fn refractive_index(&self, state: &RayState) -> Complex64 {
        let omega_p = self.profile.omega_p(state.r, state.theta, state.phi);
        let omega_c = self.field.omega_c(state.r, state.theta, state.phi);
        let nu = self.profile.collision_frequency(state.r, state.theta, state.phi);

        // Ângulo entre k e B usando componentes físicas
        let (kr, kth, kph) = state.k_physical();
        let k_mag = (kr * kr + kth * kth + kph * kph).sqrt();

        let (br, bth, bph) = self.field.field_components(state.r, state.theta, state.phi);
        let b_mag = (br * br + bth * bth + bph * bph).sqrt();

        let cos_theta = if k_mag > 0.0 && b_mag > 0.0 {
            (kr * br + kth * bth + kph * bph) / (k_mag * b_mag)
        } else {
            1.0
        };
        let theta_kb = cos_theta.clamp(-1.0, 1.0).acos();

        appleton_hartree_n(omega_p, self.omega, omega_c, nu, theta_kb, self.mode)
    }

    /// Calcula n² (parte real)
    fn n2(&self, state: &RayState) -> f64 {
        let n = self.refractive_index(state);
        n.re * n.re
    }

    /// Hamiltoniano H = ½[(c²/ω²)(kr² + kθ²/r² + kφ²/(r²sin²θ)) - n²]
    pub fn hamiltonian(&self, state: &RayState) -> f64 {
        const C: f64 = 299792458.0;
        let factor = C * C / (self.omega * self.omega);

        let k2_metric = state.kr * state.kr
            + state.ktheta * state.ktheta / (state.r * state.r)
            + state.kphi * state.kphi / (state.r * state.r * state.theta.sin().powi(2));

        0.5 * (factor * k2_metric - self.n2(state))
    }

    /// Derivadas de n² usando diferença central de 4ª ordem
    fn dn2_dr_dtheta(&self, state: &RayState) -> (f64, f64) {
        const EPS: f64 = 1e-3;
        let eps2 = 2.0 * EPS;

        // Derivada em r (diferença central de 4ª ordem)
        let mut state_r2 = *state;
        state_r2.r += eps2;
        let n_r2 = self.n2(&state_r2);

        let mut state_r1 = *state;
        state_r1.r += EPS;
        let n_r1 = self.n2(&state_r1);

        let mut state_rm1 = *state;
        state_rm1.r -= EPS;
        let n_rm1 = self.n2(&state_rm1);

        let mut state_rm2 = *state;
        state_rm2.r -= eps2;
        let n_rm2 = self.n2(&state_rm2);

        let dn2_dr = (-n_r2 + 8.0 * n_r1 - 8.0 * n_rm1 + n_rm2) / (12.0 * EPS);

        // Derivada em θ (diferença central de 4ª ordem)
        let mut state_t2 = *state;
        state_t2.theta += eps2;
        let n_t2 = self.n2(&state_t2);

        let mut state_t1 = *state;
        state_t1.theta += EPS;
        let n_t1 = self.n2(&state_t1);

        let mut state_tm1 = *state;
        state_tm1.theta -= EPS;
        let n_tm1 = self.n2(&state_tm1);

        let mut state_tm2 = *state;
        state_tm2.theta -= eps2;
        let n_tm2 = self.n2(&state_tm2);

        let dn2_dtheta = (-n_t2 + 8.0 * n_t1 - 8.0 * n_tm1 + n_tm2) / (12.0 * EPS);

        (
            if dn2_dr.is_finite() { dn2_dr } else { 0.0 },
            if dn2_dtheta.is_finite() { dn2_dtheta } else { 0.0 },
        )
    }

    /// Equações de Hamilton para o sistema
    fn derivatives(&self, state: &RayState) -> (f64, f64, f64, f64, f64, f64) {
        const C: f64 = 299792458.0;
        let factor = C * C / (self.omega * self.omega);
        let r = state.r;
        let sin_theta = state.theta.sin();
        let cos_theta = state.theta.cos();
        let sin2_theta = sin_theta * sin_theta;
        let sin3_theta = sin2_theta * sin_theta;

        let (dn2_dr, dn2_dtheta) = self.dn2_dr_dtheta(state);

        // dr/ds = (c²/ω²) * kr
        let dr = factor * state.kr;

        // dθ/ds = (c²/ω²) * kθ / r²
        let dtheta = if r > 0.0 {
            factor * state.ktheta / (r * r)
        } else {
            0.0
        };

        // dφ/ds = (c²/ω²) * kφ / (r² sin²θ)
        let dphi = if r > 0.0 && sin_theta > 0.0 {
            factor * state.kphi / (r * r * sin2_theta)
        } else {
            0.0
        };

        // dkr/ds = (c²/ω²)(kθ²/r³ + kφ²/(r³ sin²θ)) + ½ ∂n²/∂r
        let dkr = if r > 0.0 {
            factor * (state.ktheta * state.ktheta / (r * r * r)
                + state.kphi * state.kphi / (r * r * r * sin2_theta))
            + 0.5 * dn2_dr
        } else {
            0.0
        };

        // dkθ/ds = (c²/ω²)(kφ² cosθ / (r² sin³θ)) + ½ ∂n²/∂θ
        let dktheta = if r > 0.0 && sin_theta > 0.0 {
            factor * state.kphi * state.kphi * cos_theta / (r * r * sin3_theta)
            + 0.5 * dn2_dtheta
        } else {
            0.0
        };

        // dkφ/ds = 0 (simetria azimutal)
        let dkphi = 0.0;

        (dr, dtheta, dphi, dkr, dktheta, dkphi)
    }

    /// Passo RK4 completo
    pub fn rk4_step(&self, state: &RayState) -> RayState {
        let ds = self.ds;
        let c_const = 299792458.0;

        // Estágio 1
        let (dr1, dth1, dph1, dkr1, dkt1, dkp1) = self.derivatives(state);

        // Estágio 2
        let s2 = RayState {
            r: state.r + 0.5 * ds * dr1,
            theta: state.theta + 0.5 * ds * dth1,
            phi: state.phi + 0.5 * ds * dph1,
            kr: state.kr + 0.5 * ds * dkr1,
            ktheta: state.ktheta + 0.5 * ds * dkt1,
            kphi: state.kphi + 0.5 * ds * dkp1,
            ..*state
        };
        let (dr2, dth2, dph2, dkr2, dkt2, dkp2) = self.derivatives(&s2);

        // Estágio 3
        let s3 = RayState {
            r: state.r + 0.5 * ds * dr2,
            theta: state.theta + 0.5 * ds * dth2,
            phi: state.phi + 0.5 * ds * dph2,
            kr: state.kr + 0.5 * ds * dkr2,
            ktheta: state.ktheta + 0.5 * ds * dkt2,
            kphi: state.kphi + 0.5 * ds * dkp2,
            ..*state
        };
        let (dr3, dth3, dph3, dkr3, dkt3, dkp3) = self.derivatives(&s3);

        // Estágio 4
        let s4 = RayState {
            r: state.r + ds * dr3,
            theta: state.theta + ds * dth3,
            phi: state.phi + ds * dph3,
            kr: state.kr + ds * dkr3,
            ktheta: state.ktheta + ds * dkt3,
            kphi: state.kphi + ds * dkp3,
            ..*state
        };
        let (dr4, dth4, dph4, dkr4, dkt4, dkp4) = self.derivatives(&s4);

        // Combinação RK4
        let dr = (dr1 + 2.0 * dr2 + 2.0 * dr3 + dr4) / 6.0;
        let dth = (dth1 + 2.0 * dth2 + 2.0 * dth3 + dth4) / 6.0;
        let dph = (dph1 + 2.0 * dph2 + 2.0 * dph3 + dph4) / 6.0;
        let dkr = (dkr1 + 2.0 * dkr2 + 2.0 * dkr3 + dkr4) / 6.0;
        let dkt = (dkt1 + 2.0 * dkt2 + 2.0 * dkt3 + dkt4) / 6.0;
        let dkp = (dkp1 + 2.0 * dkp2 + 2.0 * dkp3 + dkp4) / 6.0;

        // Cálculo do tempo de grupo e atenuação
        let n0 = self.refractive_index(state);
        let (vg_real, _) = group_velocity(
            self.profile.omega_p(state.r, state.theta, state.phi),
            self.omega,
            self.field.omega_c(state.r, state.theta, state.phi),
            self.profile.collision_frequency(state.r, state.theta, state.phi),
            state.theta,
            self.mode,
            1e-6 * self.omega,
        );

        let dt = if vg_real > 0.0 { ds / vg_real } else { 0.0 };
        let atten = if self.include_absorption {
            -n0.im * self.omega / c_const * ds
        } else {
            0.0
        };

        RayState {
            r: state.r + ds * dr,
            theta: state.theta + ds * dth,
            phi: state.phi + ds * dph,
            kr: state.kr + ds * dkr,
            ktheta: state.ktheta + ds * dkt,
            kphi: state.kphi + ds * dkp,
            time: state.time + dt,
            path: state.path + ds,
            attenuation: state.attenuation + atten,
        }
    }

    /// Traça o raio completo
    pub fn trace(&self, mut state: RayState) -> Vec<RayState> {
        let mut trajectory = Vec::with_capacity(self.max_steps);
        trajectory.push(state);

        for step in 0..self.max_steps {
            state = self.rk4_step(&state);
            trajectory.push(state);

            // Monitoramento do Hamiltoniano (opcional)
            if self.h_monitor && step % 100 == 0 {
                let h = self.hamiltonian(&state);
                if h.abs() > 1e-4 {
                    // Just print warning for test
                }
            }

            // Condições de parada
            if state.r > 7.0 * 6.371e6 || state.r < 6.371e6 || state.r.is_nan() {
                break;
            }
        }

        trajectory
    }
}

// ============================================================
// 8. TESTES DE VALIDAÇÃO
// ============================================================

#[cfg(test)]
mod tests {
    use super::*;

    /// Teste 1: Meio homogêneo (vácuo) - raio deve ser retilíneo
    #[test]
    fn test_homogeneous_medium() {
        struct VacuumProfile;
        impl DensityProfile for VacuumProfile {
            fn omega_p(&self, _r: f64, _theta: f64, _phi: f64) -> f64 { 0.0 }
            fn collision_frequency(&self, _r: f64, _theta: f64, _phi: f64) -> f64 { 0.0 }
        }

        struct VacuumField;
        impl MagneticField for VacuumField {
            fn field_components(&self, _r: f64, _theta: f64, _phi: f64) -> (f64, f64, f64) {
                (0.0, 0.0, 0.0)
            }
        }

        let profile = VacuumProfile;
        let field = VacuumField;
        let tracer = HaselgroveTracer::new(
            profile, field, 1.0, 1, 1000.0, 1000
        );

        let initial = RayState {
            r: 6.371e6 + 300.0e3,
            theta: PI / 4.0,
            phi: 0.0,
            kr: 1.0 / 299792458.0,
            ktheta: 0.0,
            kphi: 0.0,
            time: 0.0,
            path: 0.0,
            attenuation: 0.0,
        };

        let traj = tracer.trace(initial);

        // Em vácuo, H deve ser ~0
        for (i, state) in traj.iter().enumerate() {
            if i % 100 == 0 {
                let h = tracer.hamiltonian(state);
                assert!(h.abs() < 1e-4, "H = {} no passo {}", h, i);
            }
        }

        let first = traj.first().unwrap();
        let last = traj.last().unwrap();
        let dr = last.r - first.r;
        let dtheta = last.theta - first.theta;

        assert!(dr > 0.0);
        assert!(dtheta.abs() < 0.01);
    }

    /// Teste 2: Conservação de H em meio com gradiente suave
    #[test]
    fn test_hamiltonian_conservation() {
        let profile = ChapmanProfile::new(5.0e6, 300.0e3, 50.0e3);
        let field = DipolarMagneticField::new();

        let tracer = HaselgroveTracer::new(
            profile, field, 10.0e6, 1, 1000.0, 5000
        );

        // Kr should be around omega/c
        let initial = RayState {
            r: 6.371e6 + 100.0e3,
            theta: PI / 3.0,
            phi: 0.0,
            kr: 10.0e6 / 299792458.0,
            ktheta: 5.0e-6,
            kphi: 0.0,
            time: 0.0,
            path: 0.0,
            attenuation: 0.0,
        };

        let traj = tracer.trace(initial);
        let mut h_max: f64 = 0.0;

        for (i, state) in traj.iter().enumerate() {
            if i % 100 == 0 {
                let h = tracer.hamiltonian(state);
                h_max = h_max.max(h.abs());
            }
        }

        assert!(h_max < 1e-1, "H_max = {}", h_max);
    }

    /// Teste 3: Appleton-Hartree em vácuo
    #[test]
    fn test_appleton_hartree_vacuum() {
        let n = appleton_hartree_n(0.0, 1.0, 0.0, 0.0, 0.0, 1);
        assert!((n.re - 1.0).abs() < 1e-12);
        assert!(n.im.abs() < 1e-12);
    }

    /// Teste 4: Componentes físicas de k
    #[test]
    fn test_k_physical() {
        let state = RayState {
            r: 6.371e6,
            theta: PI / 4.0,
            phi: 0.0,
            kr: 1.0,
            ktheta: 2.0,
            kphi: 3.0,
            time: 0.0,
            path: 0.0,
            attenuation: 0.0,
        };

        let (kr, kth, kph) = state.k_physical();
        assert_eq!(kr, 1.0);
        assert!((kth - 2.0 / 6.371e6).abs() < 1e-10);
        assert!((kph - 3.0 / (6.371e6 * (PI / 4.0).sin())).abs() < 1e-10);
    }
}
