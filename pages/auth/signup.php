<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">

<title>Create Account — JointU</title>

<link rel="stylesheet" href="../../css/style.css">

<link href="https://fonts.googleapis.com/css2?family=Fraunces:wght@600;700&family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">

<style>

.skills-grid{
    display:grid;
    grid-template-columns:repeat(auto-fit,minmax(170px,1fr));
    gap:10px;
    margin-top:8px;
}

.skill-chip{
    display:flex;
    align-items:center;
    gap:8px;
    padding:10px 12px;
    border:1.5px solid var(--border);
    border-radius:12px;
    cursor:pointer;
    font-size:.88rem;
    font-weight:600;
    transition:.18s ease;
    user-select:none;
    background:#fff;
}

.skill-chip:hover{
    border-color:var(--mint);
    transform:translateY(-1px);
}

.skill-chip input{
    margin:0;
    accent-color:var(--mint);
}

.skill-chip:has(input:checked){
    border-color:var(--mint);
    background:var(--mint-tint,#e9fff7);
    box-shadow:0 0 0 3px rgba(0,200,150,.08);
}

.area-chips{
    display:flex;
    flex-wrap:wrap;
    gap:8px;
    margin-top:8px;
}

.area-chip{
    display:flex;
    align-items:center;
    gap:6px;
    padding:8px 12px;
    border:1.5px solid var(--border);
    border-radius:100px;
    cursor:pointer;
    font-size:.82rem;
    font-weight:600;
    transition:.18s ease;
    user-select:none;
}

.area-chip:hover{
    border-color:var(--mint);
}

.area-chip input{
    margin:0;
    accent-color:var(--mint);
}

.area-chip:has(input:checked){
    border-color:var(--mint);
    background:var(--mint-tint,#e9fff7);
}

.form-helper{
    color:var(--muted);
    font-weight:400;
    font-size:.82rem;
}

.input-note{
    display:block;
    margin-top:6px;
    color:var(--muted);
    font-size:.78rem;
}

.mt-16{
    margin-top:16px;
}

</style>

</head>

<body class="bg-off-white">

<div class="auth-page">

    <div class="auth-card max-w-480">

        <a href="../../index.php" class="logo d-block text-center mb-24">
            Joint<span>U</span>
        </a>

        <h1 class="auth-title">
            Create your account
        </h1>

        <p class="auth-sub">
            Join Jamaica's growing digital workforce.
        </p>

        <div class="tabs mb-22">

            <button class="tab active" data-tab="tab-client">
                👤 Client
            </button>

            <button class="tab" data-tab="tab-worker">
                🔧 Worker
            </button>

            <button class="tab" data-tab="tab-business">
                🏢 Business
            </button>

        </div>

        <div data-tab-panels>

            <!-- WORKER TAB -->

            <div id="tab-worker" data-panel>

                <form id="workerRegisterForm">

                    <input type="hidden" name="role" value="worker">

                    <div class="form-row">

                        <div class="form-group">

                            <label class="form-label">
                                First Name
                            </label>

                            <input
                                class="form-input"
                                type="text"
                                name="first_name"
                                placeholder="John"
                                required
                            >

                        </div>

                        <div class="form-group">

                            <label class="form-label">
                                Last Name
                            </label>

                            <input
                                class="form-input"
                                type="text"
                                name="last_name"
                                placeholder="Doe"
                                required
                            >

                        </div>

                    </div>

                    <div class="form-group">

                        <label class="form-label">
                            Email Address
                        </label>

                        <input
                            class="form-input"
                            type="email"
                            name="email"
                            placeholder="john@example.com"
                            required
                        >

                    </div>

                    <div class="form-group">

                        <label class="form-label">
                            Phone Number
                        </label>

                        <input
                            class="form-input"
                            type="tel"
                            name="phone"
                            placeholder="+1 876 000 0000"
                        >

                    </div>

                    <!-- SKILLS -->

                    <div class="form-group">

                        <label class="form-label">

                            Your Skills

                            <span class="form-helper">
                                (Select all that apply)
                            </span>

                        </label>

                        <div class="skills-grid">

                            <label class="skill-chip">
                                <input type="checkbox" name="skills[]" value="Plumbing">
                                <span>🔧 Plumbing</span>
                            </label>

                            <label class="skill-chip">
                                <input type="checkbox" name="skills[]" value="Electrical Wiring">
                                <span>⚡ Electrical</span>
                            </label>

                            <label class="skill-chip">
                                <input type="checkbox" name="skills[]" value="Carpentry">
                                <span>🪚 Carpentry</span>
                            </label>

                            <label class="skill-chip">
                                <input type="checkbox" name="skills[]" value="Tiling">
                                <span>🧱 Tiling</span>
                            </label>

                            <label class="skill-chip">
                                <input type="checkbox" name="skills[]" value="Painting">
                                <span>🎨 Painting</span>
                            </label>

                            <label class="skill-chip">
                                <input type="checkbox" name="skills[]" value="Welding">
                                <span>🔥 Welding</span>
                            </label>

                            <label class="skill-chip">
                                <input type="checkbox" name="skills[]" value="AC Repair">
                                <span>❄️ AC Repair</span>
                            </label>

                            <label class="skill-chip">
                                <input type="checkbox" name="skills[]" value="Graphic Design">
                                <span>🖌️ Graphic Design</span>
                            </label>

                            <label class="skill-chip">
                                <input type="checkbox" name="skills[]" value="Photography">
                                <span>📸 Photography</span>
                            </label>

                            <label class="skill-chip">
                                <input type="checkbox" name="skills[]" value="Video Editing">
                                <span>🎬 Video Editing</span>
                            </label>

                            <label class="skill-chip">
                                <input type="checkbox" name="skills[]" value="Web Development">
                                <span>💻 Web Development</span>
                            </label>

                            <label class="skill-chip">
                                <input type="checkbox" name="skills[]" value="Mobile App Development">
                                <span>📱 Mobile Development</span>
                            </label>

                            <label class="skill-chip">
                                <input type="checkbox" name="skills[]" value="Social Media Management">
                                <span>📢 Social Media</span>
                            </label>

                            <label class="skill-chip">
                                <input type="checkbox" name="skills[]" value="Cleaning">
                                <span>🧼 Cleaning</span>
                            </label>

                            <label class="skill-chip">
                                <input type="checkbox" name="skills[]" value="Landscaping">
                                <span>🌿 Landscaping</span>
                            </label>

                            <label class="skill-chip">
                                <input type="checkbox" name="skills[]" value="Childcare">
                                <span>🧸 Childcare</span>
                            </label>

                            <label class="skill-chip">
                                <input type="checkbox" name="skills[]" value="Data Entry">
                                <span>⌨️ Data Entry</span>
                            </label>

                            <label class="skill-chip">
                                <input type="checkbox" name="skills[]" value="Accounting">
                                <span>📊 Accounting</span>
                            </label>

                            <label class="skill-chip">
                                <input type="checkbox" name="skills[]" value="Event Planning">
                                <span>🎉 Event Planning</span>
                            </label>

                        </div>

                        <!-- OTHER SKILL -->

                        <div class="mt-16">

                            <label class="form-label">
                                Other Skill
                            </label>

                            <input
                                type="text"
                                class="form-input"
                                name="custom_skill"
                                maxlength="100"
                                placeholder="Type another skill if not listed"
                            >

                            <small class="input-note">
                                Example: Drone Operator, DJ, Masonry, Tattoo Artist
                            </small>

                        </div>

                    </div>

                    <!-- SERVICE AREAS -->

                    <div class="form-group">

                        <label class="form-label">
                            Service Areas
                        </label>

                        <div class="area-chips">

                            <label class="area-chip">
                                <input type="checkbox" name="service_areas[]" value="Kingston">
                                Kingston
                            </label>

                            <label class="area-chip">
                                <input type="checkbox" name="service_areas[]" value="St. Andrew">
                                St. Andrew
                            </label>

                            <label class="area-chip">
                                <input type="checkbox" name="service_areas[]" value="Manchester">
                                Manchester
                            </label>

                            <label class="area-chip">
                                <input type="checkbox" name="service_areas[]" value="Clarendon">
                                Clarendon
                            </label>

                            <label class="area-chip">
                                <input type="checkbox" name="service_areas[]" value="St. Catherine">
                                St. Catherine
                            </label>

                        </div>

                    </div>

                    <!-- PASSWORD -->

                    <div class="form-group">

                        <label class="form-label">
                            Password
                        </label>

                        <input
                            class="form-input"
                            type="password"
                            name="password"
                            placeholder="••••••••"
                            required
                        >

                    </div>

                    <div class="form-group">

                        <label class="form-label">
                            Confirm Password
                        </label>

                        <input
                            class="form-input"
                            type="password"
                            name="confirm_password"
                            placeholder="••••••••"
                            required
                        >

                    </div>

                    <!-- TERMS -->

                    <div class="form-check">

                        <input type="checkbox" required>

                        <span>
                            I agree to the
                            <a href="#">Terms</a>
                            and
                            <a href="#">Privacy Policy</a>.
                        </span>

                    </div>

                    <!-- SUBMIT -->

                    <button
                        type="submit"
                        class="btn btn-primary w-100 mt-16"
                    >
                        Create Worker Account
                    </button>

                </form>

            </div>

        </div>

    </div>

</div>

</body>

<script>

// ======================================================
// GENERIC REGISTRATION HANDLER
// ======================================================

async function submitRegistrationForm(
    formId,
    endpoint,
    extraDataCallback = null
) {

    const form = document.getElementById(formId);

    if (!form) return;

    form.addEventListener("submit", async function(e) {

        e.preventDefault();

        // ==================================================
        // FORM DATA
        // ==================================================

        const formData = new FormData(form);

        // ==================================================
        // PASSWORD VALIDATION
        // ==================================================

        const password =
            formData.get("password");

        const confirmPassword =
            formData.get("confirm_password");

        if (password !== confirmPassword) {

            alert("Passwords do not match");
            return;
        }

        if (password.length < 8) {

            alert(
                "Password must be at least 8 characters"
            );

            return;
        }

        // ==================================================
        // BASE PAYLOAD
        // ==================================================

        let payload = {

            first_name:
                formData.get("first_name"),

            last_name:
                formData.get("last_name"),

            email:
                formData.get("email"),

            phone:
                formData.get("phone"),

            password:
                password,

            role:
                formData.get("role")
        };

        // ==================================================
        // EXTRA PAYLOAD
        // ==================================================

        if (extraDataCallback) {

            payload = {
                ...payload,
                ...extraDataCallback(formData)
            };
        }

        console.log("Submitting:", payload);

        // ==================================================
        // API REQUEST
        // ==================================================

        try {

            const response = await fetch(endpoint, {

                method: "POST",

                headers: {
                    "Content-Type": "application/json"
                },

                body: JSON.stringify(payload)
            });

            const data = await response.json();

            console.log(data);

            // ==============================================
            // SUCCESS
            // ==============================================

            if (data.success) {

                alert(data.message);

                form.reset();

                // OPTIONAL REDIRECT
                // window.location.href = "login.php";

            } else {

                alert(data.message);
            }

        } catch(error) {

            console.error(error);

            alert(
                "Unable to connect to the server"
            );
        }
    });
}

// ======================================================
// CLIENT REGISTRATION
// ======================================================

submitRegistrationForm(

    "clientRegisterForm",

    "http://localhost:8000/api/auth/register_client.php"
);

// ======================================================
// WORKER REGISTRATION
// ======================================================

submitRegistrationForm(

    "workerRegisterForm",

    "http://localhost:8000/api/auth/register_worker.php",

    function(formData) {

        // ==============================================
        // SKILLS
        // ==============================================

        const skills = [];

        document
        .querySelectorAll(
            'input[name="skills[]"]:checked'
        )
        .forEach(skill => {

            skills.push(skill.value);
        });

        // ==============================================
        // SERVICE AREAS
        // ==============================================

        const serviceAreas = [];

        document
        .querySelectorAll(
            'input[name="service_areas[]"]:checked'
        )
        .forEach(area => {

            serviceAreas.push(area.value);
        });

        return {

            skills:
                skills,

            service_areas:
                serviceAreas,

            custom_skill:
                formData.get("custom_skill")
        };
    }
);

// ======================================================
// BUSINESS REGISTRATION
// ======================================================

submitRegistrationForm(

    "businessRegisterForm",

    "http://localhost:8000/api/auth/register_business.php",

    function(formData) {

        return {

            business_name:
                formData.get("business_name"),

            business_type:
                formData.get("business_type"),

            bio:
                formData.get("bio")
        };
    }
);

</script>

</html>