"""
Seed script — populates MongoDB with full data for all 3 classes.
Run from backend directory:
    python -m app.scripts.seed
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from app import create_app
from app.database import (
    classes_col, subjects_col, chapters_col, topics_col,
    videos_col, quizzes_col, badges_col, users_col, user_prefs_col
)
from app.utils import now
from werkzeug.security import generate_password_hash

app = create_app("development")


def seed():
    with app.app_context():
        print("🌱 Seeding database...")

        # Clear existing data
        for col in [classes_col(), subjects_col(), chapters_col(), topics_col(),
                    videos_col(), quizzes_col(), badges_col()]:
            col.delete_many({})

        # ── CLASSES ──────────────────────────────────────────────────────────
        classes = [
            {"class_name": "Class 8",  "board": "Maharashtra Board"},
            {"class_name": "Class 9",  "board": "Maharashtra Board"},
            {"class_name": "Class 10", "board": "Maharashtra Board"},
        ]
        class_ids = []
        for c in classes:
            c["created_at"] = now()
            result = classes_col().insert_one(c)
            class_ids.append(str(result.inserted_id))
        print(f"  ✅ {len(classes)} classes inserted")

        # ── SUBJECTS (all 3 classes) ──────────────────────────────────────────
        subjects_data = [
            # Class 8
            {"subject_name": "Science",      "class_id": class_ids[0], "icon": "science"},
            {"subject_name": "Mathematics",  "class_id": class_ids[0], "icon": "math"},
            # Class 9
            {"subject_name": "Science",      "class_id": class_ids[1], "icon": "science"},
            {"subject_name": "Mathematics",  "class_id": class_ids[1], "icon": "math"},
            # Class 10
            {"subject_name": "Science",      "class_id": class_ids[2], "icon": "science"},
            {"subject_name": "Mathematics",  "class_id": class_ids[2], "icon": "math"},
        ]
        subject_ids = {}  # key: "class_index_subject" → id
        keys = ["8_sci","8_math","9_sci","9_math","10_sci","10_math"]
        for i, s in enumerate(subjects_data):
            s["created_at"] = now()
            result = subjects_col().insert_one(s)
            subject_ids[keys[i]] = str(result.inserted_id)
        print(f"  ✅ {len(subjects_data)} subjects inserted")

        # ── helper ────────────────────────────────────────────────────────────
        def add_chapter(subject_id, number, name, description, pdf_url=""):
            doc = {
                "subject_id":     subject_id,
                "chapter_number": number,
                "chapter_name":   name,
                "description":    description,
                "pdf_url":        pdf_url,   # ← leave blank; upload later via admin API
                "order_index":    number,
                "created_at":     now(),
            }
            result = chapters_col().insert_one(doc)
            return str(result.inserted_id)

        def add_topics(chapter_id, topics):
            for i, (name, content) in enumerate(topics, 1):
                topics_col().insert_one({
                    "chapter_id":  chapter_id,
                    "topic_name":  name,
                    "content":     content,
                    "order_index": i,
                })

        def add_video(chapter_id, video_id, title, duration):
            videos_col().insert_one({
                "chapter_id":       chapter_id,
                "youtube_video_id": video_id,
                "youtube_url":      f"https://www.youtube.com/watch?v={video_id}",
                "embed_url":        f"https://www.youtube.com/embed/{video_id}",
                "title":            title,
                "duration":         duration,
                "created_at":       now(),
            })

        def add_quiz(chapter_id, title, description, questions):
            quizzes_col().insert_one({
                "chapter_id":  chapter_id,
                "title":       title,
                "description": description,
                "questions":   questions,
                "created_at":  now(),
            })

        chapter_count = 0
        topic_count   = 0
        video_count   = 0
        quiz_count    = 0

        # ════════════════════════════════════════════════════════════════════
        # CLASS 8 — SCIENCE
        # ════════════════════════════════════════════════════════════════════
        sid = subject_ids["8_sci"]

        # Ch1
        ch = add_chapter(sid, 1, "Crop Production and Management",
            "Practices used in agriculture for crop production.")
        add_topics(ch, [
            ("Agricultural Practices", "Basic agricultural practices include preparation of soil, sowing, adding manure and fertilizers, irrigation, weeding, harvesting and storage."),
            ("Kharif and Rabi Crops", "Kharif crops are sown in the rainy season (June-September). Examples: paddy, maize, soybean. Rabi crops grow in winter (October-March). Examples: wheat, gram, pea."),
            ("Irrigation Methods", "Methods include moat, chain pump, dhekli, rahat, sprinkler system, and drip irrigation system."),
        ])
        add_video(ch, "MkGV1TnVPm8", "Crop Production and Management - Class 8", "14:20")
        add_quiz(ch, "Crop Production Quiz", "Test your knowledge of agricultural practices.", [
            {"question_id":"q1","question_text":"Which of these is a Kharif crop?","option_a":"Wheat","option_b":"Gram","option_c":"Paddy","option_d":"Mustard","correct_option":"C","explanation":"Paddy is grown during the rainy season (June-September), making it a Kharif crop."},
            {"question_id":"q2","question_text":"What is the process of loosening and turning the soil called?","option_a":"Sowing","option_b":"Tilling/Ploughing","option_c":"Weeding","option_d":"Harvesting","correct_option":"B","explanation":"Tilling or ploughing loosens the soil, allowing roots to penetrate deeper and improves air circulation."},
            {"question_id":"q3","question_text":"Which method of irrigation delivers water directly to the roots?","option_a":"Sprinkler","option_b":"Canal","option_c":"Drip Irrigation","option_d":"Moat","correct_option":"C","explanation":"Drip irrigation delivers water drop by drop directly to the base of plants, minimizing water waste."},
            {"question_id":"q4","question_text":"The cutting of the crop after it is mature is called:","option_a":"Threshing","option_b":"Winnowing","option_c":"Harvesting","option_d":"Sieving","correct_option":"C","explanation":"Harvesting is the process of cutting and collecting the mature crop from the field."},
            {"question_id":"q5","question_text":"Which of the following replenishes nitrogen in the soil?","option_a":"Weeding","option_b":"Leguminous plants","option_c":"Harvesting","option_d":"Irrigation","correct_option":"B","explanation":"Leguminous plants have nitrogen-fixing bacteria in their root nodules that enrich the soil with nitrogen."},
        ])
        chapter_count += 1; topic_count += 3; video_count += 1; quiz_count += 1

        # Ch2
        ch = add_chapter(sid, 2, "Microorganisms: Friend and Foe",
            "Study of microorganisms and their role in nature.")
        add_topics(ch, [
            ("Types of Microorganisms", "Microorganisms include bacteria, fungi, protozoa, algae, and viruses. They are found in soil, water, air and inside other organisms."),
            ("Useful Microorganisms", "Microorganisms are used in making curd, bread, cake (yeast), antibiotics (penicillin from Penicillium fungi), and nitrogen fixation."),
            ("Harmful Microorganisms", "Some microorganisms cause diseases like cholera, typhoid (bacteria), malaria (protozoa), and common cold (virus)."),
        ])
        add_video(ch, "PxkIVLNhIj0", "Microorganisms Friend and Foe - Class 8 Science", "16:45")
        add_quiz(ch, "Microorganisms Quiz", "Test your knowledge of microorganisms.", [
            {"question_id":"q1","question_text":"Which microorganism is used to make bread?","option_a":"Bacteria","option_b":"Yeast","option_c":"Algae","option_d":"Protozoa","correct_option":"B","explanation":"Yeast (a fungus) is used in baking bread. It ferments sugars and releases CO2 which makes bread rise."},
            {"question_id":"q2","question_text":"Malaria is caused by:","option_a":"Bacteria","option_b":"Virus","option_c":"Protozoa","option_d":"Fungi","correct_option":"C","explanation":"Malaria is caused by Plasmodium, a protozoan parasite, transmitted through the bite of female Anopheles mosquito."},
            {"question_id":"q3","question_text":"The first antibiotic discovered was:","option_a":"Streptomycin","option_b":"Tetracycline","option_c":"Penicillin","option_d":"Erythromycin","correct_option":"C","explanation":"Penicillin was discovered by Alexander Fleming in 1928 from the Penicillium fungus."},
            {"question_id":"q4","question_text":"Which of these is NOT a microorganism?","option_a":"Bacteria","option_b":"Virus","option_c":"Mosquito","option_d":"Fungi","correct_option":"C","explanation":"Mosquito is an insect, not a microorganism. Microorganisms include bacteria, viruses, fungi, algae, and protozoa."},
            {"question_id":"q5","question_text":"Curd is formed from milk by:","option_a":"Yeast","option_b":"Lactobacillus bacteria","option_c":"Rhizobium","option_d":"Virus","correct_option":"B","explanation":"Lactobacillus bacteria convert milk into curd through the process of fermentation."},
        ])
        chapter_count += 1; topic_count += 3; video_count += 1; quiz_count += 1

        # Ch3
        ch = add_chapter(sid, 3, "Synthetic Fibres and Plastics",
            "Types and properties of synthetic fibres and plastics.")
        add_topics(ch, [
            ("Types of Synthetic Fibres", "Synthetic fibres include rayon, nylon, polyester, and acrylic. They are made from petrochemicals through chemical processes."),
            ("Characteristics of Plastics", "Plastics are non-reactive, light, strong, and durable. They are either thermoplastics (melt on heating) or thermosetting plastics (do not melt)."),
            ("Plastics and Environment", "Plastics are non-biodegradable and cause pollution. The 4R principle - Reduce, Reuse, Recycle, Recover helps manage plastic waste."),
        ])
        add_video(ch, "haGFoReGeow", "Synthetic Fibres and Plastics Class 8", "13:10")
        chapter_count += 1; topic_count += 3; video_count += 1

        # ════════════════════════════════════════════════════════════════════
        # CLASS 8 — MATHEMATICS
        # ════════════════════════════════════════════════════════════════════
        sid = subject_ids["8_math"]

        # Ch1
        ch = add_chapter(sid, 1, "Rational Numbers",
            "Properties and operations on rational numbers.")
        add_topics(ch, [
            ("Properties of Rational Numbers", "Rational numbers are closed under addition, subtraction, and multiplication. Division by zero is not defined. They satisfy commutativity, associativity, and distributivity."),
            ("Rational Numbers on Number Line", "Every rational number can be represented on a number line. Between any two rational numbers, there exist infinitely many rational numbers."),
            ("Operations on Rational Numbers", "Standard operations of addition, subtraction, multiplication and division apply. For addition: a/b + c/d = (ad+bc)/bd."),
        ])
        add_video(ch, "cLP7B66lbnU", "Rational Numbers Class 8 Maths", "18:30")
        add_quiz(ch, "Rational Numbers Quiz", "Test your understanding of rational numbers.", [
            {"question_id":"q1","question_text":"Which of the following is a rational number?","option_a":"√2","option_b":"π","option_c":"3/4","option_d":"√3","correct_option":"C","explanation":"3/4 is a rational number as it can be expressed in the form p/q where q≠0. √2, π, √3 are irrational."},
            {"question_id":"q2","question_text":"The additive identity for rational numbers is:","option_a":"1","option_b":"-1","option_c":"0","option_d":"1/2","correct_option":"C","explanation":"0 is the additive identity because adding 0 to any rational number gives the same number: a + 0 = a."},
            {"question_id":"q3","question_text":"What is the multiplicative inverse of -5/7?","option_a":"5/7","option_b":"-7/5","option_c":"7/5","option_d":"-5/7","correct_option":"B","explanation":"The multiplicative inverse of -5/7 is -7/5 because (-5/7) × (-7/5) = 1."},
            {"question_id":"q4","question_text":"Which property is shown by: 2/3 × (1/4 + 1/5) = 2/3 × 1/4 + 2/3 × 1/5?","option_a":"Associative","option_b":"Commutative","option_c":"Distributive","option_d":"Closure","correct_option":"C","explanation":"This shows the distributive property of multiplication over addition."},
            {"question_id":"q5","question_text":"Between 0 and 1, how many rational numbers exist?","option_a":"0","option_b":"10","option_c":"100","option_d":"Infinitely many","correct_option":"D","explanation":"Between any two distinct rational numbers, there exist infinitely many rational numbers."},
        ])
        chapter_count += 1; topic_count += 3; video_count += 1; quiz_count += 1

        # Ch2
        ch = add_chapter(sid, 2, "Linear Equations in One Variable",
            "Solving linear equations and their applications.")
        add_topics(ch, [
            ("Linear Equations", "A linear equation in one variable is of the form ax + b = c. The solution is obtained by isolating the variable using inverse operations."),
            ("Solving Equations", "Steps: (1) Simplify both sides, (2) Collect variable terms on one side, (3) Collect constants on other side, (4) Divide to find the variable."),
            ("Word Problems", "Linear equations can solve problems involving age, money, speed, and mixtures by translating words into mathematical expressions."),
        ])
        add_video(ch, "h8eTaVGJvZg", "Linear Equations in One Variable Class 8", "20:15")
        chapter_count += 1; topic_count += 3; video_count += 1

        # Ch3
        ch = add_chapter(sid, 3, "Understanding Quadrilaterals",
            "Properties and types of quadrilaterals.")
        add_topics(ch, [
            ("Types of Quadrilaterals", "Quadrilaterals include parallelogram, rectangle, rhombus, square, trapezium, and kite. Sum of all angles of a quadrilateral = 360°."),
            ("Properties of Parallelogram", "In a parallelogram: opposite sides are equal and parallel, opposite angles are equal, diagonals bisect each other."),
            ("Special Quadrilaterals", "Rectangle: all angles 90°. Rhombus: all sides equal. Square: all sides equal + all angles 90°. Trapezium: one pair of parallel sides."),
        ])
        add_video(ch, "GFnlq5gWgqA", "Understanding Quadrilaterals Class 8 Maths", "17:40")
        chapter_count += 1; topic_count += 3; video_count += 1

        # ════════════════════════════════════════════════════════════════════
        # CLASS 9 — SCIENCE
        # ════════════════════════════════════════════════════════════════════
        sid = subject_ids["9_sci"]

        # Ch1
        ch = add_chapter(sid, 1, "Matter in Our Surroundings",
            "Physical nature, properties, and states of matter.")
        add_topics(ch, [
            ("States of Matter", "Matter exists in three states: solid, liquid, and gas. Solids have definite shape and volume; liquids have definite volume but no fixed shape; gases have neither."),
            ("Interconversion of States", "Melting (solid→liquid), evaporation (liquid→gas), condensation (gas→liquid), freezing (liquid→solid), sublimation (solid→gas directly)."),
            ("Effect of Temperature and Pressure", "Increasing temperature increases kinetic energy. Gases can be liquefied by increasing pressure and decreasing temperature."),
        ])
        add_video(ch, "hV4s0eE_oLg", "Matter in Our Surroundings - Class 9 Science", "15:50")
        add_quiz(ch, "Matter Quiz", "Test your knowledge of states of matter.", [
            {"question_id":"q1","question_text":"Which state of matter has definite volume but no definite shape?","option_a":"Solid","option_b":"Liquid","option_c":"Gas","option_d":"Plasma","correct_option":"B","explanation":"Liquids have a definite volume but take the shape of the container. Solids have both definite shape and volume."},
            {"question_id":"q2","question_text":"The process of conversion of solid directly to gas is called:","option_a":"Melting","option_b":"Evaporation","option_c":"Sublimation","option_d":"Condensation","correct_option":"C","explanation":"Sublimation is the process where a solid directly converts to gas without passing through the liquid state. Example: dry ice, camphor."},
            {"question_id":"q3","question_text":"SI unit of temperature is:","option_a":"Celsius","option_b":"Fahrenheit","option_c":"Kelvin","option_d":"Rankine","correct_option":"C","explanation":"The SI unit of temperature is Kelvin (K). Conversion: K = °C + 273.15"},
            {"question_id":"q4","question_text":"Gases can be liquefied by:","option_a":"Increasing temperature only","option_b":"Decreasing pressure only","option_c":"Increasing pressure and decreasing temperature","option_d":"Decreasing pressure and increasing temperature","correct_option":"C","explanation":"Gases are liquefied by applying high pressure and lowering temperature, bringing molecules closer together."},
            {"question_id":"q5","question_text":"Which has the highest kinetic energy at the same temperature?","option_a":"Solid","option_b":"Liquid","option_c":"Gas","option_d":"All equal","correct_option":"C","explanation":"Gas particles have the highest kinetic energy as they move freely and rapidly compared to solids and liquids."},
        ])
        chapter_count += 1; topic_count += 3; video_count += 1; quiz_count += 1

        # Ch2
        ch = add_chapter(sid, 2, "Is Matter Around Us Pure?",
            "Pure substances, mixtures, and separation techniques.")
        add_topics(ch, [
            ("Pure Substances and Mixtures", "A pure substance has fixed composition (elements and compounds). Mixtures have variable composition and can be homogeneous (solutions) or heterogeneous."),
            ("Solutions", "A solution is a homogeneous mixture. The solute dissolves in the solvent. Concentration = (solute mass / solution mass) × 100."),
            ("Separation Techniques", "Methods include evaporation, filtration, distillation, crystallisation, chromatography, and centrifugation depending on mixture type."),
        ])
        add_video(ch, "ZUb3UNkMR7I", "Is Matter Around Us Pure - Class 9 Science", "18:20")
        chapter_count += 1; topic_count += 3; video_count += 1

        # Ch3
        ch = add_chapter(sid, 3, "Atoms and Molecules",
            "Structure of atoms and molecules, atomic mass and formulae.")
        add_topics(ch, [
            ("Laws of Chemical Combination", "Law of Conservation of Mass: mass is conserved. Law of Constant Proportions: elements in a compound are always in fixed mass ratio."),
            ("Atoms and Molecules", "Atom is the smallest unit of an element. Molecule is the smallest unit of a compound. Atomicity is the number of atoms in one molecule."),
            ("Mole Concept", "1 mole = 6.022 × 10²³ particles (Avogadro number). Molar mass = atomic or molecular mass in grams. Used to count particles in a sample."),
        ])
        add_video(ch, "GMcTCFQcBBE", "Atoms and Molecules Class 9 Science", "22:10")
        add_quiz(ch, "Atoms and Molecules Quiz", "Test your understanding of atomic concepts.", [
            {"question_id":"q1","question_text":"Who proposed the atomic theory?","option_a":"Newton","option_b":"John Dalton","option_c":"Einstein","option_d":"Bohr","correct_option":"B","explanation":"John Dalton proposed the atomic theory in 1808, stating that matter is made of indivisible atoms."},
            {"question_id":"q2","question_text":"Avogadro's number is:","option_a":"6.022 × 10²¹","option_b":"6.022 × 10²³","option_c":"6.022 × 10²⁵","option_d":"6.022 × 10²²","correct_option":"B","explanation":"Avogadro's number = 6.022 × 10²³ — the number of particles in one mole of a substance."},
            {"question_id":"q3","question_text":"The atomicity of ozone (O₃) is:","option_a":"1","option_b":"2","option_c":"3","option_d":"4","correct_option":"C","explanation":"Ozone (O₃) has 3 oxygen atoms per molecule, so its atomicity is 3."},
            {"question_id":"q4","question_text":"Molecular mass of water (H₂O) is:","option_a":"16 u","option_b":"18 u","option_c":"20 u","option_d":"14 u","correct_option":"B","explanation":"H₂O: 2×1 (H) + 16 (O) = 18 u."},
            {"question_id":"q5","question_text":"Which law states that elements combine in a fixed mass ratio?","option_a":"Law of Conservation of Mass","option_b":"Law of Multiple Proportions","option_c":"Law of Constant Proportions","option_d":"Dalton's Law","correct_option":"C","explanation":"The Law of Constant Proportions (Proust's Law) states that a pure compound always contains the same elements in the same mass ratio."},
        ])
        chapter_count += 1; topic_count += 3; video_count += 1; quiz_count += 1

        # ════════════════════════════════════════════════════════════════════
        # CLASS 9 — MATHEMATICS
        # ════════════════════════════════════════════════════════════════════
        sid = subject_ids["9_math"]

        # Ch1
        ch = add_chapter(sid, 1, "Number Systems",
            "Real numbers, irrational numbers, and number line representation.")
        add_topics(ch, [
            ("Natural, Whole and Integer Numbers", "Natural numbers: 1,2,3... Whole numbers: 0,1,2... Integers: ...,-2,-1,0,1,2... Rational numbers: p/q form where q≠0."),
            ("Irrational Numbers", "Numbers that cannot be expressed as p/q. Examples: √2, √3, π. Their decimal expansion is non-terminating and non-repeating."),
            ("Laws of Exponents for Real Numbers", "aᵐ × aⁿ = aᵐ⁺ⁿ, aᵐ/aⁿ = aᵐ⁻ⁿ, (aᵐ)ⁿ = aᵐⁿ, aᵐ × bᵐ = (ab)ᵐ. These apply to real numbers as well."),
        ])
        add_video(ch, "JCH8YWyCTpI", "Number Systems Class 9 Maths", "19:30")
        chapter_count += 1; topic_count += 3; video_count += 1

        # Ch2
        ch = add_chapter(sid, 2, "Polynomials",
            "Types, operations, and factorisation of polynomials.")
        add_topics(ch, [
            ("Types of Polynomials", "Based on degree: constant (0), linear (1), quadratic (2), cubic (3). Based on terms: monomial (1), binomial (2), trinomial (3)."),
            ("Remainder and Factor Theorem", "Remainder Theorem: When p(x) is divided by (x-a), remainder = p(a). Factor Theorem: (x-a) is a factor of p(x) if and only if p(a) = 0."),
            ("Algebraic Identities", "(a+b)² = a²+2ab+b², (a-b)² = a²-2ab+b², (a+b)(a-b) = a²-b², (a+b+c)² = a²+b²+c²+2ab+2bc+2ca."),
        ])
        add_video(ch, "KFWXRTmkNmQ", "Polynomials Class 9 Maths", "21:00")
        add_quiz(ch, "Polynomials Quiz", "Test your knowledge of polynomials.", [
            {"question_id":"q1","question_text":"Degree of polynomial 5x³ + 3x² - 7 is:","option_a":"1","option_b":"2","option_c":"3","option_d":"0","correct_option":"C","explanation":"The degree of a polynomial is the highest power of the variable. Here, highest power is 3."},
            {"question_id":"q2","question_text":"Value of polynomial p(x) = x² - 3x + 2 at x = 1 is:","option_a":"0","option_b":"1","option_c":"2","option_d":"-1","correct_option":"A","explanation":"p(1) = 1² - 3(1) + 2 = 1 - 3 + 2 = 0. So (x-1) is a factor."},
            {"question_id":"q3","question_text":"Which is NOT a polynomial?","option_a":"x² + 2x + 1","option_b":"3x - 7","option_c":"x + 1/x","option_d":"5","correct_option":"C","explanation":"x + 1/x = x + x⁻¹ has a negative exponent, so it is not a polynomial."},
            {"question_id":"q4","question_text":"(a + b)² equals:","option_a":"a² + b²","option_b":"a² - 2ab + b²","option_c":"a² + 2ab + b²","option_d":"2a + 2b","correct_option":"C","explanation":"(a+b)² = a² + 2ab + b² is a standard algebraic identity."},
            {"question_id":"q5","question_text":"Zeroes of polynomial x² - 5x + 6 are:","option_a":"2 and 3","option_b":"1 and 6","option_c":"-2 and -3","option_d":"2 and -3","correct_option":"A","explanation":"x²-5x+6 = (x-2)(x-3). Setting each factor to zero: x=2 or x=3."},
        ])
        chapter_count += 1; topic_count += 3; video_count += 1; quiz_count += 1

        # Ch3
        ch = add_chapter(sid, 3, "Coordinate Geometry",
            "Cartesian system, plotting points, and quadrants.")
        add_topics(ch, [
            ("Cartesian System", "The Cartesian system has two perpendicular number lines: x-axis (horizontal) and y-axis (vertical), intersecting at origin (0,0)."),
            ("Quadrants", "The axes divide the plane into 4 quadrants. Q1:(+,+), Q2:(-,+), Q3:(-,-), Q4:(+,-)."),
            ("Plotting Points", "A point (x, y): x is the horizontal distance from origin, y is the vertical distance. The point (0, y) lies on y-axis; (x, 0) on x-axis."),
        ])
        add_video(ch, "9wOK00YIDL8", "Coordinate Geometry Class 9 Maths", "16:00")
        chapter_count += 1; topic_count += 3; video_count += 1

        # ════════════════════════════════════════════════════════════════════
        # CLASS 10 — SCIENCE
        # ════════════════════════════════════════════════════════════════════
        sid = subject_ids["10_sci"]

        # Ch1
        ch = add_chapter(sid, 1, "Chemical Reactions and Equations",
            "Balancing equations and types of chemical reactions.")
        add_topics(ch, [
            ("Types of Chemical Reactions", "Combination, decomposition, displacement, double displacement, and oxidation-reduction (redox) reactions."),
            ("Balancing Chemical Equations", "Balancing ensures the law of conservation of mass is satisfied. Number of atoms of each element must be equal on both sides."),
            ("Oxidation and Reduction", "Oxidation: addition of oxygen/removal of hydrogen/increase in oxidation state. Reduction: opposite. Both occur simultaneously (redox reaction)."),
        ])
        add_video(ch, "N3kfOCz-WrQ", "Chemical Reactions and Equations Class 10", "12:34")
        add_quiz(ch, "Chemical Reactions Quiz", "Test your knowledge of chemical reactions.", [
            {"question_id":"q1","question_text":"Which is a combination reaction?","option_a":"CaCO3 → CaO + CO2","option_b":"2H2 + O2 → 2H2O","option_c":"Fe + CuSO4 → FeSO4 + Cu","option_d":"NaOH + HCl → NaCl + H2O","correct_option":"B","explanation":"Combination reactions involve two or more substances combining to form a single product."},
            {"question_id":"q2","question_text":"Rusting of iron is:","option_a":"Combination reaction","option_b":"Decomposition reaction","option_c":"Oxidation reaction","option_d":"Displacement reaction","correct_option":"C","explanation":"Rusting involves iron reacting with oxygen and water - an oxidation process."},
            {"question_id":"q3","question_text":"The law of conservation of mass states:","option_a":"Mass can be created","option_b":"Mass can be destroyed","option_c":"Total mass of reactants = Total mass of products","option_d":"Mass changes in reactions","correct_option":"C","explanation":"Antoine Lavoisier's law: mass is neither created nor destroyed in a chemical reaction."},
            {"question_id":"q4","question_text":"Which type: AB + CD → AD + CB?","option_a":"Combination","option_b":"Decomposition","option_c":"Displacement","option_d":"Double displacement","correct_option":"D","explanation":"Double displacement reactions involve exchange of ions between two compounds."},
            {"question_id":"q5","question_text":"What is produced when Mg burns in air?","option_a":"MgCl2","option_b":"MgSO4","option_c":"MgO","option_d":"Mg(OH)2","correct_option":"C","explanation":"2Mg + O2 → 2MgO. Magnesium burns with a bright white flame producing magnesium oxide."},
        ])
        chapter_count += 1; topic_count += 3; video_count += 1; quiz_count += 1

        # Ch2
        ch = add_chapter(sid, 2, "Acids, Bases and Salts",
            "Properties and reactions of acids, bases and salts.")
        add_topics(ch, [
            ("Properties of Acids and Bases", "Acids: sour taste, turn blue litmus red, pH < 7, release H⁺ ions. Bases: bitter taste, turn red litmus blue, pH > 7, release OH⁻ ions."),
            ("Neutralisation Reaction", "Acid + Base → Salt + Water. This is called a neutralisation reaction. The pH of the resulting solution depends on relative strengths."),
            ("pH Scale and Importance", "pH scale ranges from 0-14. pH < 7 is acidic, pH = 7 is neutral, pH > 7 is basic. pH is important in agriculture, medicine, and industry."),
        ])
        add_video(ch, "6vLZPpOJHME", "Acids Bases and Salts Class 10", "15:22")
        chapter_count += 1; topic_count += 3; video_count += 1

        # Ch3
        ch = add_chapter(sid, 3, "Metals and Non-metals",
            "Physical and chemical properties of metals and non-metals.")
        add_topics(ch, [
            ("Physical Properties", "Metals: lustrous, hard, malleable, ductile, conductors. Non-metals: dull, brittle, non-conductors (except graphite). Mercury is a liquid metal."),
            ("Chemical Properties of Metals", "Metals react with oxygen (oxides), water (hydroxides + hydrogen), acids (salt + hydrogen), and other metal salts (displacement)."),
            ("Reactivity Series", "Order: K > Na > Ca > Mg > Al > Zn > Fe > Pb > H > Cu > Ag > Au. Metals above hydrogen displace H₂ from acids. Used to predict displacement reactions."),
        ])
        add_video(ch, "kJFx5bxQCpM", "Metals and Non-Metals Class 10 Science", "19:45")
        add_quiz(ch, "Metals and Non-metals Quiz", "Test your knowledge of metals and non-metals.", [
            {"question_id":"q1","question_text":"Which metal is liquid at room temperature?","option_a":"Iron","option_b":"Copper","option_c":"Mercury","option_d":"Aluminium","correct_option":"C","explanation":"Mercury (Hg) is the only metal that exists as a liquid at room temperature."},
            {"question_id":"q2","question_text":"Which non-metal conducts electricity?","option_a":"Sulphur","option_b":"Phosphorus","option_c":"Graphite","option_d":"Bromine","correct_option":"C","explanation":"Graphite (an allotrope of carbon) is the only non-metal that conducts electricity."},
            {"question_id":"q3","question_text":"The most reactive metal is:","option_a":"Gold","option_b":"Potassium","option_c":"Iron","option_d":"Copper","correct_option":"B","explanation":"Potassium (K) is at the top of the reactivity series, making it the most reactive common metal."},
            {"question_id":"q4","question_text":"Metal + Acid gives:","option_a":"Salt + Water","option_b":"Salt + Hydrogen","option_c":"Oxide + Water","option_d":"Hydroxide + Hydrogen","correct_option":"B","explanation":"Metal + Acid → Salt + Hydrogen gas. Example: Zn + H2SO4 → ZnSO4 + H2↑"},
            {"question_id":"q5","question_text":"Which property allows metals to be drawn into wires?","option_a":"Malleability","option_b":"Lustre","option_c":"Conductivity","option_d":"Ductility","correct_option":"D","explanation":"Ductility is the property that allows metals to be drawn into thin wires without breaking."},
        ])
        chapter_count += 1; topic_count += 3; video_count += 1; quiz_count += 1

        # ════════════════════════════════════════════════════════════════════
        # CLASS 10 — MATHEMATICS
        # ════════════════════════════════════════════════════════════════════
        sid = subject_ids["10_math"]

        # Ch1
        ch = add_chapter(sid, 1, "Real Numbers",
            "Euclid's division lemma, prime factorisation, and irrationality.")
        add_topics(ch, [
            ("Euclid's Division Lemma", "For any two positive integers a and b, there exist unique integers q and r such that a = bq + r, where 0 ≤ r < b. Used to find HCF."),
            ("Fundamental Theorem of Arithmetic", "Every composite number can be expressed as a product of primes in a unique way (ignoring order). Used to find HCF and LCM."),
            ("Irrational Numbers", "Proof that √2, √3, √5 are irrational using contradiction. A number is irrational if its decimal expansion is non-terminating non-repeating."),
        ])
        add_video(ch, "TLPQ0bJCgbA", "Real Numbers Class 10 Maths", "20:00")
        add_quiz(ch, "Real Numbers Quiz", "Test your knowledge of real numbers.", [
            {"question_id":"q1","question_text":"HCF of 12 and 18 is:","option_a":"6","option_b":"3","option_c":"9","option_d":"12","correct_option":"A","explanation":"12 = 2²×3, 18 = 2×3². HCF = 2×3 = 6."},
            {"question_id":"q2","question_text":"LCM × HCF = ?","option_a":"Sum of numbers","option_b":"Difference of numbers","option_c":"Product of numbers","option_d":"None of these","correct_option":"C","explanation":"For any two positive integers, LCM × HCF = Product of the numbers."},
            {"question_id":"q3","question_text":"Which is irrational?","option_a":"√4","option_b":"√9","option_c":"√7","option_d":"√16","correct_option":"C","explanation":"√7 ≈ 2.6457... is non-terminating non-repeating, hence irrational. Others are perfect squares."},
            {"question_id":"q4","question_text":"Euclid's Division Lemma: a = bq + r, where:","option_a":"0 < r < b","option_b":"0 ≤ r < b","option_c":"0 ≤ r ≤ b","option_d":"r > b","correct_option":"B","explanation":"In Euclid's Division Lemma, the remainder r satisfies 0 ≤ r < b (r can be zero)."},
            {"question_id":"q5","question_text":"The decimal expansion of 17/8 is:","option_a":"Non-terminating repeating","option_b":"Non-terminating non-repeating","option_c":"Terminating","option_d":"Cannot be determined","correct_option":"C","explanation":"17/8 = 2.125. Since denominator 8 = 2³ has only factor 2, the decimal terminates."},
        ])
        chapter_count += 1; topic_count += 3; video_count += 1; quiz_count += 1

        # Ch2
        ch = add_chapter(sid, 2, "Polynomials",
            "Zeros of polynomials and relationship with coefficients.")
        add_topics(ch, [
            ("Zeros of a Polynomial", "The zero of a polynomial p(x) is a value of x for which p(x) = 0. Geometrically, the number of zeros = number of times the curve crosses the x-axis."),
            ("Relationship Between Zeros and Coefficients", "For quadratic ax²+bx+c: sum of zeros = -b/a, product of zeros = c/a. For cubic ax³+bx²+cx+d: sum of zeros = -b/a, sum of products of pairs = c/a, product = -d/a."),
            ("Division Algorithm", "p(x) = g(x) × q(x) + r(x) where degree(r) < degree(g). Used to find zeros and factorise polynomials."),
        ])
        add_video(ch, "XkjmZWIhFWw", "Polynomials Class 10 Maths", "18:45")
        chapter_count += 1; topic_count += 3; video_count += 1

        # Ch3
        ch = add_chapter(sid, 3, "Pair of Linear Equations in Two Variables",
            "Methods to solve simultaneous linear equations.")
        add_topics(ch, [
            ("Graphical Method", "Plot both equations as lines. Intersecting lines → unique solution. Parallel lines → no solution. Coincident lines → infinite solutions."),
            ("Algebraic Methods", "Substitution: express one variable in terms of the other. Elimination: multiply and add/subtract equations to eliminate one variable."),
            ("Cross Multiplication Method", "For a₁x+b₁y+c₁=0 and a₂x+b₂y+c₂=0: x/(b₁c₂-b₂c₁) = y/(c₁a₂-c₂a₁) = 1/(a₁b₂-a₂b₁)."),
        ])
        add_video(ch, "qZe-7tBWiyw", "Pair of Linear Equations Class 10 Maths", "23:00")
        add_quiz(ch, "Linear Equations Quiz", "Solve systems of linear equations.", [
            {"question_id":"q1","question_text":"If 2x + y = 5 and x - y = 1, then x =","option_a":"1","option_b":"2","option_c":"3","option_d":"4","correct_option":"B","explanation":"Adding: 3x = 6 → x = 2. Then y = 5 - 2(2) = 1."},
            {"question_id":"q2","question_text":"Two lines are parallel when:","option_a":"a1/a2 = b1/b2 = c1/c2","option_b":"a1/a2 ≠ b1/b2","option_c":"a1/a2 = b1/b2 ≠ c1/c2","option_d":"a1b2 - a2b1 ≠ 0","correct_option":"C","explanation":"Lines are parallel (no solution) when a1/a2 = b1/b2 ≠ c1/c2."},
            {"question_id":"q3","question_text":"The solution of x + y = 4 and x - y = 2 is:","option_a":"x=2, y=2","option_b":"x=3, y=1","option_c":"x=1, y=3","option_d":"x=4, y=0","correct_option":"B","explanation":"Adding: 2x = 6 → x = 3. Subtracting: 2y = 2 → y = 1."},
            {"question_id":"q4","question_text":"Graphically, a unique solution means the lines are:","option_a":"Parallel","option_b":"Coincident","option_c":"Intersecting at one point","option_d":"Perpendicular only","correct_option":"C","explanation":"Two lines with a unique solution intersect at exactly one point."},
            {"question_id":"q5","question_text":"If a1/a2 = b1/b2 = c1/c2, the equations have:","option_a":"No solution","option_b":"Unique solution","option_c":"Infinitely many solutions","option_d":"Two solutions","correct_option":"C","explanation":"When all three ratios are equal, the lines are coincident — every point on one line satisfies the other."},
        ])
        chapter_count += 1; topic_count += 3; video_count += 1; quiz_count += 1

        print(f"  ✅ {chapter_count} chapters inserted")
        print(f"  ✅ {topic_count} topics inserted")
        print(f"  ✅ {video_count} videos inserted")
        print(f"  ✅ {quiz_count} quizzes inserted")

        # ── BADGES ────────────────────────────────────────────────────────────
        badges_data = [
            {"badge_name": "First Quiz",      "description": "Complete your first quiz",      "criteria_type": "quiz_count", "criteria_value": 1,    "icon_url": "🎯"},
            {"badge_name": "Quiz Enthusiast", "description": "Complete 5 quizzes",            "criteria_type": "quiz_count", "criteria_value": 5,    "icon_url": "📚"},
            {"badge_name": "Quiz Master",     "description": "Complete 20 quizzes",           "criteria_type": "quiz_count", "criteria_value": 20,   "icon_url": "🏆"},
            {"badge_name": "Point Starter",   "description": "Earn 50 points",               "criteria_type": "points",     "criteria_value": 50,   "icon_url": "⭐"},
            {"badge_name": "Scholar",         "description": "Earn 500 points",              "criteria_type": "points",     "criteria_value": 500,  "icon_url": "🎓"},
            {"badge_name": "Champion",        "description": "Earn 2000 points",             "criteria_type": "points",     "criteria_value": 2000, "icon_url": "👑"},
            {"badge_name": "3-Day Streak",    "description": "Maintain a 3-day streak",      "criteria_type": "streak",     "criteria_value": 3,    "icon_url": "🔥"},
            {"badge_name": "Week Warrior",    "description": "Maintain a 7-day streak",      "criteria_type": "streak",     "criteria_value": 7,    "icon_url": "💪"},
            {"badge_name": "Streak Legend",   "description": "Maintain a 30-day streak",     "criteria_type": "streak",     "criteria_value": 30,   "icon_url": "🌟"},
        ]
        for b in badges_data:
            b["created_at"] = now()
            badges_col().insert_one(b)
        print(f"  ✅ {len(badges_data)} badges inserted")

        # ── ADMIN USER ────────────────────────────────────────────────────────
        if not users_col().find_one({"email": "admin@scimathub.com"}):
            admin = {
                "full_name": "Admin",
                "email": "admin@scimathub.com",
                "phone": "9999999999",
                "password_hash": generate_password_hash("admin123"),
                "role": "admin",
                "class_id": None,
                "profile_image": "",
                "total_points": 0,
                "streak_count": 0,
                "failed_attempts": 0,
                "last_activity_date": None,
                "is_active": True,
                "created_at": now(),
                "updated_at": now(),
            }
            result = users_col().insert_one(admin)
            user_prefs_col().insert_one({
                "user_id": str(result.inserted_id),
                "dark_mode": False, "language": "en",
                "notifications_enabled": True, "study_reminder_enabled": True,
                "badge_alert_enabled": True, "quiz_reminder_enabled": True,
                "show_on_leaderboard": False, "show_streak_publicly": True,
                "difficulty_level": "medium", "preferred_subject": None,
                "font_size": "medium", "wifi_only_download": False,
                "created_at": now(), "updated_at": now(),
            })
            print("  ✅ Admin user: admin@scimathub.com / admin123")
        else:
            print("  ⏭  Admin already exists")

        print("\n🎉 Seeding complete!")
        print(f"   3 classes × 2 subjects × 3 chapters = 18 chapters total")
        print(f"   {quiz_count} quizzes with 5 questions each")
        print(f"   Admin: admin@scimathub.com | Password: admin123")
        print("\n📄 To add PDF notes for a chapter, use the admin API:")
        print("   PUT /api/chapters/<chapter_id>")
        print('   Body: { "pdf_url": "https://your-server.com/path/chapter.pdf" }')


if __name__ == "__main__":
    seed()