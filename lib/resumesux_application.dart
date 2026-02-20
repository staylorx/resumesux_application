library;

// re-export the domain layer
export 'package:resumesux_domain/resumesux_domain.dart';

export 'src/usecases/create_applicant_usecase.dart';
export 'src/usecases/generate_application_usecase.dart';
export 'src/usecases/get_config_usecase.dart';
export 'src/usecases/get_applicant_usecase.dart';
export 'src/usecases/get_all_applicants_usecase.dart';
export 'src/usecases/update_applicant_usecase.dart';
export 'src/usecases/remove_applicant_usecase.dart';
export 'src/usecases/get_default_provider_usecase.dart';
export 'src/usecases/generate_resume_usecase.dart';
export 'src/usecases/generate_cover_letter_usecase.dart';
export 'src/usecases/generate_feedback_usecase.dart';
export 'src/usecases/extract_jobreq_from_file_usecase.dart';
export 'src/usecases/update_job_req_usecase.dart';
export 'src/usecases/get_job_req_usecase.dart';
export 'src/usecases/remove_jobreq_usecase.dart';
export 'src/usecases/save_asset_ai_response_usecase.dart';
export 'src/usecases/save_cover_letter_ai_response_usecase.dart';
export 'src/usecases/save_feedback_ai_response_usecase.dart';
export 'src/usecases/save_gig_ai_response_usecase.dart';
export 'src/usecases/save_job_req_ai_response_usecase.dart';
export 'src/usecases/save_resume_ai_response_usecase.dart';

export 'src/services/ai_service_factory.dart';
export 'src/services/ai_service.dart';
export 'src/services/database_service.dart';
export 'src/services/handle_generator.dart';

export 'src/repositories/gig_repository.dart';
export 'src/repositories/asset_repository.dart';
export 'src/repositories/job_req_repository.dart';
export 'src/repositories/config_repository.dart';
export 'src/repositories/applicant_repository.dart';
export 'src/repositories/application_repository.dart';
export 'src/repositories/resume_repository.dart';
export 'src/repositories/cover_letter_repository.dart';
export 'src/repositories/feedback_repository.dart';
export 'src/repositories/file_repository.dart';
export 'src/repositories/doc_repository.dart';
export 'src/repositories/transaction.dart';
export 'src/repositories/unit_of_work.dart';

export 'src/failure.dart';
